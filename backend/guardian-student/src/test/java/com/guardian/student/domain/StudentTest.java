package com.guardian.student.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** Domain rules for {@link Student}. No Spring, no database. */
class StudentTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final SchoolId SCHOOL = SchoolId.of(UUID.randomUUID());

  private static Student aStudent() {
    return Student.create(
        TENANT,
        SCHOOL,
        null,
        null,
        AdmissionNumber.of("GW-2024-0117"),
        "Aarav",
        "Sharma",
        LocalDate.of(2015, 4, 12),
        true);
  }

  @Test
  @BusinessRule("BR-STU-001")
  @DisplayName("a new student is active and belongs to the school they were enrolled at")
  void newStudentIsActive() {
    Student student = aStudent();

    assertThat(student.enrolmentStatus()).isEqualTo(EnrolmentStatus.ACTIVE);
    assertThat(student.schoolId()).isEqualTo(SCHOOL);
    assertThat(student.version()).isZero();
  }

  @Test
  @BusinessRule("BR-STU-001")
  @DisplayName("names must not be blank")
  void namesAreRequired() {
    assertThatThrownBy(
            () ->
                Student.create(
                    TENANT,
                    SCHOOL,
                    null,
                    null,
                    AdmissionNumber.of("GW-1"),
                    "   ",
                    "Sharma",
                    null,
                    true))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING);
  }

  @Test
  @DisplayName("state changes return new instances; the original is untouched")
  void updatesReturnNewInstances() {
    Student original = aStudent();
    Student withdrawn = original.withdraw();

    assertThat(original.enrolmentStatus()).isEqualTo(EnrolmentStatus.ACTIVE);
    assertThat(withdrawn.enrolmentStatus()).isEqualTo(EnrolmentStatus.WITHDRAWN);
    // Identity is preserved across a state change — it is the same child.
    assertThat(withdrawn).isEqualTo(original);
  }

  @Test
  @BusinessRule("BR-STU-005")
  @DisplayName("withdrawal also clears transport eligibility")
  void withdrawalClearsTransportEligibility() {
    Student withdrawn = aStudent().withdraw();

    assertThat(withdrawn.transportEligible()).isFalse();
    // Otherwise a withdrawn student still passes any filter that checks eligibility alone.
    assertThat(withdrawn.isAssignable()).isFalse();
  }

  @Test
  @BusinessRule("BR-STU-005")
  @DisplayName("an update never changes the school or the admission number")
  void updateCannotMoveOrRenumberTheStudent() {
    Student updated =
        aStudent()
            .updateDetails("Aarav", "Sharma-Patel", LocalDate.of(2015, 4, 12), null, null, false);

    assertThat(updated.schoolId()).isEqualTo(SCHOOL);
    assertThat(updated.admissionNo().value()).isEqualTo("GW-2024-0117");
  }

  @Test
  @DisplayName("an inactive student is not assignable even while transport-eligible")
  void assignabilityNeedsBothConditions() {
    Student eligibleButWithdrawn = aStudent().withdraw();
    assertThat(eligibleButWithdrawn.isAssignable()).isFalse();

    Student activeButIneligible =
        aStudent().updateDetails("Aarav", "Sharma", null, null, null, false);
    assertThat(activeButIneligible.enrolmentStatus()).isEqualTo(EnrolmentStatus.ACTIVE);
    assertThat(activeButIneligible.isAssignable()).isFalse();
  }

  @Test
  @DisplayName("toString carries identifiers, never the child's name")
  void toStringOmitsPersonalData() {
    assertThat(aStudent().toString()).doesNotContain("Aarav").doesNotContain("Sharma");
  }

  @Nested
  @DisplayName("AdmissionNumber")
  class AdmissionNumberTest {

    @Test
    @BusinessRule("BR-STU-003")
    @DisplayName("normalises to upper case so one number cannot be entered twice")
    void normalisesToUpperCase() {
      assertThat(AdmissionNumber.of("gw-2024-0117").value()).isEqualTo("GW-2024-0117");
      assertThat(AdmissionNumber.of("  gw-1  ")).isEqualTo(AdmissionNumber.of("GW-1"));
    }

    @Test
    @BusinessRule("BR-STU-003")
    @DisplayName("accepts the numbering schemes schools actually arrive with")
    void acceptsRealWorldFormats() {
      assertThat(AdmissionNumber.of("2024/117").value()).isEqualTo("2024/117");
      assertThat(AdmissionNumber.of("117").value()).isEqualTo("117");
      assertThat(AdmissionNumber.of("GW 2024 117").value()).isEqualTo("GW 2024 117");
    }

    @Test
    @BusinessRule("BR-STU-003")
    @DisplayName("rejects a value that identifies nobody")
    void rejectsBlank() {
      assertThatThrownBy(() -> AdmissionNumber.of("   "))
          .isInstanceOf(BusinessRuleViolationException.class)
          .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
          .isEqualTo(ErrorCode.VALIDATION_INVALID_FORMAT);
    }

    @Test
    @BusinessRule("BR-STU-003")
    @DisplayName("rejects a value longer than the column")
    void rejectsOverlongValue() {
      assertThatThrownBy(() -> AdmissionNumber.of("A".repeat(65)))
          .isInstanceOf(BusinessRuleViolationException.class);
    }
  }
}
