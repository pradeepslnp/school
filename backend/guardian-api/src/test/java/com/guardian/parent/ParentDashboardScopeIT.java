package com.guardian.parent;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.AbstractIntegrationTest;
import com.guardian.common.BusinessRule;
import com.guardian.parent.application.port.ParentReadModel;
import com.guardian.parent.application.result.DashboardView;
import com.guardian.parent.domain.ChildJourney;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Scope invariants for the parent dashboard (ADR-0010, verification 2).
 *
 * <p>The projection in {@code JdbcParentReadModel} enforces two different boundaries at once, and a
 * defect in either is silent — the query still returns rows, they are just the wrong family's:
 *
 * <ul>
 *   <li><strong>Scope</strong> (BR-IAM-005): a guardian sees the children they hold an active link
 *       to, and no others — including children at the same school.
 *   <li><strong>Tenant</strong> (BR-TEN-004): row-level security still applies, so the same
 *       guardian id under another tenant's context returns nothing at all.
 * </ul>
 *
 * <p>Both are asserted against the real schema, as the application role, because that is the only
 * configuration in which either could fail.
 */
class ParentDashboardScopeIT extends AbstractIntegrationTest {

  @Autowired private ParentReadModel readModel;

  private static final UUID SCHOOL_A = UUID.randomUUID();
  private static final UUID GUARDIAN_A_USER = UUID.randomUUID();
  private static final UUID GUARDIAN_A = UUID.randomUUID();
  private static final UUID CHILD_LINKED = UUID.randomUUID();
  private static final UUID CHILD_ALSO_LINKED = UUID.randomUUID();
  private static final UUID CHILD_SAME_SCHOOL_NOT_LINKED = UUID.randomUUID();

  private static final UUID SCHOOL_B = UUID.randomUUID();
  private static final UUID GUARDIAN_B_USER = UUID.randomUUID();
  private static final UUID GUARDIAN_B = UUID.randomUUID();
  private static final UUID CHILD_OTHER_TENANT = UUID.randomUUID();

  @BeforeEach
  void seedTwoFamiliesInTwoTenants() {
    JdbcTemplate owner = ownerJdbcTemplate();

    school(owner, SCHOOL_A, ORGANIZATION_A, "SCH-A");
    user(owner, GUARDIAN_A_USER, ORGANIZATION_A, "911111111111", "Meera");
    guardian(owner, GUARDIAN_A, ORGANIZATION_A, GUARDIAN_A_USER, "Meera", "911111111111");
    student(owner, CHILD_LINKED, ORGANIZATION_A, SCHOOL_A, "A-001", "Aarav");
    student(owner, CHILD_ALSO_LINKED, ORGANIZATION_A, SCHOOL_A, "A-002", "Ananya");
    // The control. Same tenant, same school, no link to this guardian — the row the projection
    // must not return, and the one a missing join condition would leak.
    student(owner, CHILD_SAME_SCHOOL_NOT_LINKED, ORGANIZATION_A, SCHOOL_A, "A-003", "Rohan");
    link(owner, ORGANIZATION_A, GUARDIAN_A, CHILD_LINKED);
    link(owner, ORGANIZATION_A, GUARDIAN_A, CHILD_ALSO_LINKED);

    school(owner, SCHOOL_B, ORGANIZATION_B, "SCH-B");
    user(owner, GUARDIAN_B_USER, ORGANIZATION_B, "922222222222", "Priya");
    guardian(owner, GUARDIAN_B, ORGANIZATION_B, GUARDIAN_B_USER, "Priya", "922222222222");
    student(owner, CHILD_OTHER_TENANT, ORGANIZATION_B, SCHOOL_B, "B-001", "Kabir");
    link(owner, ORGANIZATION_B, GUARDIAN_B, CHILD_OTHER_TENANT);
  }

  @Test
  @BusinessRule("BR-IAM-005")
  @DisplayName("a guardian sees only the children they hold an active link to")
  void dashboardIsScopedToOwnChildren() {
    DashboardView view = inTenant(TENANT_A, () -> readModel.childrenOf(GUARDIAN_A_USER));

    assertThat(names(view.children()))
        .as("only linked children, never another family's child at the same school")
        .containsExactlyInAnyOrder("Aarav Test", "Ananya Test");
  }

  @Test
  @BusinessRule("BR-IAM-005")
  @DisplayName("deactivating a link removes the child from the dashboard immediately")
  void deactivatedLinkIsNotVisible() {
    ownerJdbcTemplate()
        .update(
            "UPDATE guardian_student_links SET is_active = false WHERE student_id = ?",
            CHILD_ALSO_LINKED);

    DashboardView view = inTenant(TENANT_A, () -> readModel.childrenOf(GUARDIAN_A_USER));

    // Deactivation takes effect at once (BR-GRD-004); there is no cache between this query and
    // the link table, and this test is what keeps it that way.
    assertThat(names(view.children())).containsExactly("Aarav Test");
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("the same guardian returns nothing under another tenant's context")
  void dashboardIsTenantIsolated() {
    DashboardView view = inTenant(TENANT_B, () -> readModel.childrenOf(GUARDIAN_A_USER));

    // Row-level security, not a WHERE clause in the projection: tenant isolation must hold even
    // if every join in the query were wrong.
    assertThat(view.children()).as("tenant A's guardian is invisible under tenant B").isEmpty();
  }

  @Test
  @BusinessRule("BR-IAM-005")
  @DisplayName("child detail refuses a student the caller is not linked to")
  void childDetailIsScoped() {
    assertThat(inTenant(TENANT_A, () -> readModel.childDetail(GUARDIAN_A_USER, CHILD_LINKED)))
        .as("own child is readable")
        .isPresent();

    assertThat(
            inTenant(
                TENANT_A,
                () -> readModel.childDetail(GUARDIAN_A_USER, CHILD_SAME_SCHOOL_NOT_LINKED)))
        .as("a child at the same school with no link is not readable")
        .isEmpty();
  }

  @Test
  @DisplayName("a guardian with no linked children gets an empty dashboard, not a failure")
  void noChildrenIsAnOrdinaryState() {
    UUID strangerUser = UUID.randomUUID();
    user(ownerJdbcTemplate(), strangerUser, ORGANIZATION_A, "933333333333", "Nobody");

    DashboardView view = inTenant(TENANT_A, () -> readModel.childrenOf(strangerUser));

    // "No children linked yet" is something the app explains, so it must not arrive as an error.
    assertThat(view.children()).isEmpty();
    assertThat(view.observedAt()).isNotNull();
  }

  private static List<String> names(List<ChildJourney> children) {
    return children.stream().map(ChildJourney::displayName).toList();
  }

  // --- fixtures ---------------------------------------------------------------------------

  private void school(JdbcTemplate owner, UUID id, UUID tenant, String code) {
    owner.update(
        """
        INSERT INTO schools (id, tenant_id, organization_id, code, name, timezone,
                             latitude, longitude, geofence_radius_m, status)
        VALUES (?, ?, ?, ?, ?, 'Asia/Kolkata', 28.5, 77.2, 150, 'ACTIVE')
        """,
        id,
        tenant,
        tenant,
        code,
        code);
  }

  private void user(JdbcTemplate owner, UUID id, UUID tenant, String phone, String firstName) {
    owner.update(
        """
        INSERT INTO users (id, tenant_id, phone, first_name, last_name, status)
        VALUES (?, ?, ?, ?, 'Test', 'ACTIVE')
        """,
        id,
        tenant,
        phone,
        firstName);
  }

  private void guardian(
      JdbcTemplate owner, UUID id, UUID tenant, UUID userId, String firstName, String phone) {
    owner.update(
        """
        INSERT INTO guardians (id, tenant_id, user_id, first_name, last_name, phone, is_active)
        VALUES (?, ?, ?, ?, 'Test', ?, true)
        """,
        id,
        tenant,
        userId,
        firstName,
        phone);
  }

  private void student(
      JdbcTemplate owner, UUID id, UUID tenant, UUID schoolId, String admissionNo, String first) {
    owner.update(
        """
        INSERT INTO students (id, tenant_id, school_id, admission_no, first_name, last_name,
                              enrolment_status)
        VALUES (?, ?, ?, ?, ?, 'Test', 'ACTIVE')
        """,
        id,
        tenant,
        schoolId,
        admissionNo,
        first);
  }

  private void link(JdbcTemplate owner, UUID tenant, UUID guardianId, UUID studentId) {
    owner.update(
        """
        INSERT INTO guardian_student_links (tenant_id, guardian_id, student_id,
                                            relationship_type, can_view, is_active)
        VALUES (?, ?, ?, 'MOTHER', true, true)
        """,
        tenant,
        guardianId,
        studentId);
  }
}
