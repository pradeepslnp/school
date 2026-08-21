package com.guardian.student;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.AbstractIntegrationTest;
import com.guardian.common.BusinessRule;
import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.port.StudentPage;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.Student;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Tenant isolation for the student module's repository, following the pattern {@code
 * SchoolTenantIsolationIT} establishes for every module.
 *
 * <p>The property matters more here than almost anywhere else: these rows are children. A query
 * that omitted a tenant filter must return <em>zero rows</em> rather than another school's register
 * — and note that no method under test contains a tenant predicate at all.
 */
class StudentTenantIsolationIT extends AbstractIntegrationTest {

  private static final UUID SCHOOL_A_ID = UUID.randomUUID();
  private static final UUID SCHOOL_B_ID = UUID.randomUUID();

  @Autowired private StudentRepository studentRepository;

  @BeforeEach
  void seedSchools() {
    // Seeded as owner: these are the tenants' own schools, created before any request context.
    JdbcTemplate owner = ownerJdbcTemplate();
    insertSchool(owner, SCHOOL_A_ID, ORGANIZATION_A, "SCH-A");
    insertSchool(owner, SCHOOL_B_ID, ORGANIZATION_B, "SCH-B");
  }

  private void insertSchool(JdbcTemplate owner, UUID id, UUID tenantId, String code) {
    owner.update(
        """
        INSERT INTO schools (id, tenant_id, organization_id, code, name, timezone,
                             latitude, longitude, geofence_radius_m, status)
        VALUES (?, ?, ?, ?, ?, 'Asia/Kolkata', 12.971600, 77.594600, 150, 'ACTIVE')
        """,
        id,
        tenantId,
        tenantId,
        code,
        "Campus " + code);
  }

  private Student studentFor(TenantId tenant, UUID schoolId, String admissionNo) {
    return Student.create(
        tenant,
        SchoolId.of(schoolId),
        null,
        null,
        AdmissionNumber.of(admissionNo),
        "Aarav",
        "Sharma",
        LocalDate.of(2015, 4, 12),
        true);
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("a register written under one tenant is invisible to another")
  void registersAreTenantScoped() {
    Student saved =
        inTenant(TENANT_A, () -> studentRepository.save(studentFor(TENANT_A, SCHOOL_A_ID, "A-1")));

    StudentPage fromOwner =
        inTenant(
            TENANT_A, () -> studentRepository.findBySchool(SchoolId.of(SCHOOL_A_ID), null, 50));
    assertThat(fromOwner.students()).extracting(Student::id).contains(saved.id());

    StudentPage fromOther =
        inTenant(
            TENANT_B, () -> studentRepository.findBySchool(SchoolId.of(SCHOOL_A_ID), null, 50));
    assertThat(fromOther.students()).isEmpty();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("a direct lookup by ID across tenants finds nothing")
  void findByIdIsTenantScoped() {
    Student saved =
        inTenant(TENANT_A, () -> studentRepository.save(studentFor(TENANT_A, SCHOOL_A_ID, "A-2")));

    assertThat(inTenant(TENANT_A, () -> studentRepository.findById(saved.id()))).isPresent();
    assertThat(inTenant(TENANT_B, () -> studentRepository.findById(saved.id()))).isEmpty();
  }

  @Test
  @BusinessRule("BR-STU-003")
  @DisplayName("the admission-number check does not leak another tenant's numbering")
  void existsCheckIsTenantScoped() {
    inTenant(TENANT_A, () -> studentRepository.save(studentFor(TENANT_A, SCHOOL_A_ID, "SHARED-1")));

    assertThat(
            inTenant(
                TENANT_A,
                () ->
                    studentRepository.existsByAdmissionNo(
                        SchoolId.of(SCHOOL_A_ID), AdmissionNumber.of("SHARED-1"))))
        .isTrue();

    // The same number is free in another organization — uniqueness is per school, per tenant, and
    // a true here would tell tenant B that tenant A has a student they cannot see.
    assertThat(
            inTenant(
                TENANT_B,
                () ->
                    studentRepository.existsByAdmissionNo(
                        SchoolId.of(SCHOOL_B_ID), AdmissionNumber.of("SHARED-1"))))
        .isFalse();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("with no tenant context, the repository returns nothing")
  void noContextReturnsNothing() {
    inTenant(TENANT_A, () -> studentRepository.save(studentFor(TENANT_A, SCHOOL_A_ID, "A-3")));

    StudentPage page =
        withoutTenantContext(
            () -> studentRepository.findBySchool(SchoolId.of(SCHOOL_A_ID), null, 50));

    assertThat(page.students()).isEmpty();
  }

  @Test
  @DisplayName("paging walks the register without repeating or skipping a student")
  void pagingIsStableAcrossPages() {
    inTenant(
        TENANT_A,
        () -> {
          for (int i = 1; i <= 5; i++) {
            studentRepository.save(studentFor(TENANT_A, SCHOOL_A_ID, "P-" + i));
          }
        });

    StudentPage first =
        inTenant(TENANT_A, () -> studentRepository.findBySchool(SchoolId.of(SCHOOL_A_ID), null, 2));
    assertThat(first.students()).hasSize(2);
    assertThat(first.hasMore()).isTrue();

    StudentPage second =
        inTenant(
            TENANT_A,
            () ->
                studentRepository.findBySchool(
                    SchoolId.of(SCHOOL_A_ID), AdmissionNumber.of(first.nextCursor()), 2));
    assertThat(second.students()).hasSize(2);

    StudentPage third =
        inTenant(
            TENANT_A,
            () ->
                studentRepository.findBySchool(
                    SchoolId.of(SCHOOL_A_ID), AdmissionNumber.of(second.nextCursor()), 2));
    assertThat(third.students()).hasSize(1);
    assertThat(third.hasMore()).isFalse();

    // Five distinct students across three pages — no repeat, nobody missed.
    assertThat(
            java.util.stream.Stream.of(first, second, third)
                .flatMap(page -> page.students().stream())
                .map(student -> student.admissionNo().value())
                .distinct()
                .toList())
        .containsExactly("P-1", "P-2", "P-3", "P-4", "P-5");
  }
}
