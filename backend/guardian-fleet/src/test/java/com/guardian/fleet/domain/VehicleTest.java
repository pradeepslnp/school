package com.guardian.fleet.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.tenant.TenantId;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** Domain unit tests — no Spring context, no database. */
class VehicleTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final SchoolId SCHOOL = SchoolId.of(UUID.randomUUID());

  private static Vehicle aVehicle() {
    return Vehicle.create(
        TENANT,
        SCHOOL,
        RegistrationNo.of("dl1pc1234"),
        "Bus 12",
        VehicleType.BUS,
        SeatingCapacity.of(42),
        "Sharma Transport");
  }

  @Test
  @DisplayName("a new vehicle is active")
  void newVehicleIsActive() {
    assertThat(aVehicle().isActive()).isTrue();
  }

  @Test
  @DisplayName("state changes return new instances; the original is untouched")
  void stateChangesAreImmutable() {
    Vehicle original = aVehicle();

    Vehicle inMaintenance = original.changeStatus(VehicleStatus.MAINTENANCE);

    assertThat(original.isActive()).isTrue();
    assertThat(inMaintenance.isActive()).isFalse();
    assertThat(inMaintenance.id()).isEqualTo(original.id());
  }

  @Test
  void displayNameMustNotBeBlank() {
    assertThatThrownBy(
            () ->
                Vehicle.create(
                    TENANT,
                    SCHOOL,
                    RegistrationNo.of("DL1PC1234"),
                    "   ",
                    VehicleType.BUS,
                    SeatingCapacity.of(42),
                    null))
        .isInstanceOf(BusinessRuleViolationException.class);
  }

  @Nested
  @DisplayName("assertEligibleToStart")
  class AssertEligibleToStartTest {

    @Test
    void doesNotThrowForAnActiveVehicle() {
      aVehicle().assertEligibleToStart();
    }

    @Test
    void throwsForAVehicleInMaintenance() {
      Vehicle inMaintenance = aVehicle().changeStatus(VehicleStatus.MAINTENANCE);

      assertThatThrownBy(inMaintenance::assertEligibleToStart)
          .isInstanceOf(BusinessRuleViolationException.class);
    }
  }

  @Nested
  @DisplayName("RegistrationNo")
  class RegistrationNoTest {

    @Test
    @DisplayName("normalises to upper case — DL1PC1234 and dl1pc1234 are the same vehicle")
    void normalisesToUpperCase() {
      assertThat(RegistrationNo.of(" dl1pc1234 ").value()).isEqualTo("DL1PC1234");
    }

    @Test
    void rejectsBlank() {
      assertThatThrownBy(() -> RegistrationNo.of("   "))
          .isInstanceOf(BusinessRuleViolationException.class);
    }
  }

  @Nested
  @DisplayName("SeatingCapacity")
  class SeatingCapacityTest {

    @Test
    @DisplayName("rejects zero and negative capacity — a vehicle carries nobody or fewer")
    void rejectsNonPositive() {
      assertThatThrownBy(() -> SeatingCapacity.of(0))
          .isInstanceOf(BusinessRuleViolationException.class);
      assertThatThrownBy(() -> SeatingCapacity.of(-1))
          .isInstanceOf(BusinessRuleViolationException.class);
    }

    @Test
    void acceptsAPositiveValue() {
      assertThat(SeatingCapacity.of(42).seats()).isEqualTo(42);
    }
  }
}
