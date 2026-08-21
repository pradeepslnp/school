package com.guardian.staff.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** Domain unit tests — no Spring context, no database. */
class TransportStaffTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final SchoolId SCHOOL = SchoolId.of(UUID.randomUUID());

  private static TransportStaff aStaff() {
    return TransportStaff.create(
        TENANT, SCHOOL, StaffType.DRIVER, "EMP-001", "Ravi", "Kumar", "9876500001", null);
  }

  @Test
  @DisplayName("a newly created staff member is active and pending verification")
  void newStaffIsActiveAndPending() {
    TransportStaff staff = aStaff();

    assertThat(staff.active()).isTrue();
    assertThat(staff.verificationStatus()).isEqualTo(VerificationStatus.PENDING);
    assertThat(staff.verifiedUntil()).isEmpty();
  }

  @Test
  @DisplayName("state changes return new instances; the original is untouched")
  void stateChangesAreImmutable() {
    TransportStaff original = aStaff();

    TransportStaff deactivated = original.deactivate();

    assertThat(original.active()).isTrue();
    assertThat(deactivated.active()).isFalse();
    assertThat(deactivated.id()).isEqualTo(original.id());
  }

  @Test
  void firstNameMustNotBeBlank() {
    assertThatThrownBy(
            () ->
                TransportStaff.create(
                    TENANT,
                    SCHOOL,
                    StaffType.DRIVER,
                    "EMP-001",
                    "   ",
                    "Kumar",
                    "9876500001",
                    null))
        .isInstanceOf(BusinessRuleViolationException.class);
  }

  @Nested
  @DisplayName("construction — BR-STAFF-002")
  class VerifiedRequiresVerifiedUntilTest {

    @Test
    @BusinessRule("BR-STAFF-002")
    @DisplayName("a VERIFIED record with no verifiedUntil cannot be constructed")
    void rejectsVerifiedWithoutVerifiedUntil() {
      assertThatThrownBy(
              () ->
                  new TransportStaff(
                      StaffId.generate(),
                      TENANT,
                      SCHOOL,
                      null,
                      StaffType.DRIVER,
                      "EMP-001",
                      "Ravi",
                      "Kumar",
                      "9876500001",
                      null,
                      null,
                      VerificationStatus.VERIFIED,
                      null,
                      true,
                      0L))
          .isInstanceOf(BusinessRuleViolationException.class);
    }

    @Test
    @DisplayName("a VERIFIED record with a verifiedUntil constructs cleanly")
    void acceptsVerifiedWithVerifiedUntil() {
      TransportStaff staff =
          new TransportStaff(
              StaffId.generate(),
              TENANT,
              SCHOOL,
              null,
              StaffType.DRIVER,
              "EMP-001",
              "Ravi",
              "Kumar",
              "9876500001",
              null,
              null,
              VerificationStatus.VERIFIED,
              LocalDate.of(2027, 1, 1),
              true,
              0L);

      assertThat(staff.verificationStatus()).isEqualTo(VerificationStatus.VERIFIED);
    }
  }

  @Nested
  @DisplayName("verify")
  class VerifyTest {

    @Test
    @BusinessRule("BR-STAFF-002")
    @DisplayName("verify requires a non-null verifiedUntil")
    void verifyRequiresVerifiedUntil() {
      assertThatThrownBy(() -> aStaff().verify(null)).isInstanceOf(NullPointerException.class);
    }

    @Test
    void verifySetsStatusAndDate() {
      TransportStaff verified = aStaff().verify(LocalDate.of(2027, 1, 1));

      assertThat(verified.verificationStatus()).isEqualTo(VerificationStatus.VERIFIED);
      assertThat(verified.verifiedUntil()).contains(LocalDate.of(2027, 1, 1));
    }
  }

  @Nested
  @DisplayName("isVerifiedAsOf — BR-STAFF-002")
  class IsVerifiedAsOfTest {

    @Test
    @BusinessRule("BR-STAFF-002")
    @DisplayName("verified through the boundary day, lapsed the day after")
    void verifiedThroughTheBoundaryDay() {
      TransportStaff verified = aStaff().verify(LocalDate.of(2026, 8, 3));

      assertThat(verified.isVerifiedAsOf(LocalDate.of(2026, 8, 3))).isTrue();
      assertThat(verified.isVerifiedAsOf(LocalDate.of(2026, 8, 4))).isFalse();
    }

    @Test
    @DisplayName("a PENDING staff member is never verified")
    void pendingIsNeverVerified() {
      assertThat(aStaff().isVerifiedAsOf(LocalDate.of(2026, 8, 3))).isFalse();
    }
  }
}
