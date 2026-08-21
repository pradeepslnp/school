package com.guardian.staff.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class StaffCredentialTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final StaffId STAFF = StaffId.generate();

  @Test
  @BusinessRule("BR-STAFF-001")
  @DisplayName("a credential expiring today is expired as of tomorrow, not as of today")
  void isExpiredComparesAgainstTheGivenDate() {
    StaffCredential credential =
        StaffCredential.create(
            TENANT,
            STAFF,
            "DRIVING_LICENCE",
            "DL-1",
            "LMV",
            null,
            LocalDate.of(2026, 8, 1),
            true,
            null);

    assertThat(credential.isExpired(LocalDate.of(2026, 8, 1))).isFalse();
    assertThat(credential.isExpired(LocalDate.of(2026, 8, 2))).isTrue();
  }

  @Test
  @BusinessRule("BR-STAFF-001")
  @DisplayName("coversClass matches case-insensitively; a null class never covers anything")
  void coversClassIsCaseInsensitiveAndNullSafe() {
    StaffCredential withClass =
        StaffCredential.create(
            TENANT,
            STAFF,
            "DRIVING_LICENCE",
            "DL-1",
            "LMV",
            null,
            LocalDate.of(2027, 1, 1),
            true,
            null);
    StaffCredential withoutClass =
        StaffCredential.create(
            TENANT,
            STAFF,
            "DRIVING_LICENCE",
            "DL-2",
            null,
            null,
            LocalDate.of(2027, 1, 1),
            true,
            null);

    assertThat(withClass.coversClass("lmv")).isTrue();
    assertThat(withClass.coversClass("HMV")).isFalse();
    assertThat(withoutClass.coversClass("LMV")).isFalse();
  }

  @Test
  @DisplayName("an issue date on or after the expiry date is rejected")
  void rejectsIssuedOnAfterOrEqualToExpiresOn() {
    assertThatThrownBy(
            () ->
                StaffCredential.create(
                    TENANT,
                    STAFF,
                    "DRIVING_LICENCE",
                    "DL-1",
                    "LMV",
                    LocalDate.of(2026, 8, 1),
                    LocalDate.of(2026, 8, 1),
                    true,
                    null))
        .isInstanceOf(BusinessRuleViolationException.class);
  }
}
