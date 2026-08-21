package com.guardian.fleet.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.tenant.TenantId;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class DeviceTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());

  private static Device aDevice() {
    return Device.register(
        TENANT, DeviceIdentifier.of("IMEI-123456789012345"), "TRACCAR", "hashed");
  }

  @Test
  @DisplayName("a newly registered device is unassigned")
  void newDeviceIsUnassigned() {
    assertThat(aDevice().isAssigned()).isFalse();
  }

  @Test
  @BusinessRule("BR-FLEET-004")
  @DisplayName("assigning a device to a vehicle is a new, immutable instance")
  void assignReturnsANewInstance() {
    Device device = aDevice();
    VehicleId vehicleId = VehicleId.generate();

    Device assigned = device.assignTo(vehicleId);

    assertThat(device.isAssigned()).isFalse();
    assertThat(assigned.isAssigned()).isTrue();
    assertThat(assigned.vehicleId()).contains(vehicleId);
  }

  @Test
  @DisplayName("unassigning clears the vehicle")
  void unassignClearsTheVehicle() {
    Device assigned = aDevice().assignTo(VehicleId.generate());

    assertThat(assigned.unassign().isAssigned()).isFalse();
  }

  @Test
  @DisplayName("a blank device identifier is rejected")
  void rejectsBlankIdentifier() {
    // Format validation only — not a citation of BR-FLEET-006, which governs what the
    // ingestion pipeline does with an unknown identifier, not what this constructor accepts.
    assertThatThrownBy(() -> DeviceIdentifier.of("  "))
        .isInstanceOf(BusinessRuleViolationException.class);
  }
}
