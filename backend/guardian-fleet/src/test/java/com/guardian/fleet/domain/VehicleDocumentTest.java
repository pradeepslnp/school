package com.guardian.fleet.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class VehicleDocumentTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final VehicleId VEHICLE = VehicleId.generate();

  @Test
  @BusinessRule("BR-FLEET-002")
  @DisplayName("a document expiring today is expired as of tomorrow, not as of today")
  void isExpiredComparesAgainstTheGivenDate() {
    VehicleDocument document =
        VehicleDocument.create(
            TENANT,
            VEHICLE,
            "FITNESS_CERTIFICATE",
            "FC-1",
            null,
            LocalDate.of(2026, 8, 1),
            true,
            null);

    assertThat(document.isExpired(LocalDate.of(2026, 8, 1))).isFalse();
    assertThat(document.isExpired(LocalDate.of(2026, 8, 2))).isTrue();
  }

  @Test
  @DisplayName("expiresWithin includes the boundary day")
  void expiresWithinIncludesTheBoundary() {
    VehicleDocument document =
        VehicleDocument.create(
            TENANT,
            VEHICLE,
            "FITNESS_CERTIFICATE",
            "FC-1",
            null,
            LocalDate.of(2026, 8, 31),
            true,
            null);

    assertThat(document.expiresWithin(LocalDate.of(2026, 8, 1), 30)).isTrue();
    assertThat(document.expiresWithin(LocalDate.of(2026, 8, 1), 29)).isFalse();
  }

  @Test
  @DisplayName("an issue date on or after the expiry date is rejected")
  void rejectsIssuedOnAfterOrEqualToExpiresOn() {
    assertThatThrownBy(
            () ->
                VehicleDocument.create(
                    TENANT,
                    VEHICLE,
                    "FITNESS_CERTIFICATE",
                    "FC-1",
                    LocalDate.of(2026, 8, 1),
                    LocalDate.of(2026, 8, 1),
                    true,
                    null))
        .isInstanceOf(BusinessRuleViolationException.class);
  }
}
