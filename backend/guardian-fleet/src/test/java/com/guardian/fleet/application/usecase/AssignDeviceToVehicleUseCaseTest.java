package com.guardian.fleet.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.port.DeviceRepository;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceIdentifier;
import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.SeatingCapacity;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleId;
import com.guardian.fleet.domain.VehicleType;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md, "uq_devices_vehicle_active". */
@ExtendWith(MockitoExtension.class)
class AssignDeviceToVehicleUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private DeviceRepository deviceRepository;
  @Mock private VehicleRepository vehicleRepository;
  @Mock private AuditPort auditPort;

  private AssignDeviceToVehicleUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new AssignDeviceToVehicleUseCase(deviceRepository, vehicleRepository, auditPort);
    TenantContext.set(TENANT);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static Vehicle aVehicle(VehicleId id) {
    return new Vehicle(
        id,
        TENANT,
        SchoolId.of(UUID.randomUUID()),
        RegistrationNo.of("DL1PC1234"),
        "Bus 12",
        VehicleType.BUS,
        SeatingCapacity.of(42),
        null,
        com.guardian.fleet.domain.VehicleStatus.ACTIVE,
        0L);
  }

  @Test
  @DisplayName("assigns an unassigned device to a vehicle with no active device")
  void assignsDevice() {
    Device device = Device.register(TENANT, DeviceIdentifier.of("IMEI-1"), "TRACCAR", "hash");
    VehicleId vehicleId = VehicleId.generate();

    when(deviceRepository.findById(device.id())).thenReturn(Optional.of(device));
    when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(aVehicle(vehicleId)));
    when(deviceRepository.existsActiveForVehicle(vehicleId)).thenReturn(false);
    when(deviceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Device assigned = useCase.execute(device.id(), vehicleId, ACTOR, "FLEET_MANAGER");

    assertThat(assigned.vehicleId()).contains(vehicleId);
  }

  @Test
  @BusinessRule("BR-FLEET-004")
  @DisplayName("refuses to assign a second active device to one vehicle")
  void refusesASecondActiveDevice() {
    Device device = Device.register(TENANT, DeviceIdentifier.of("IMEI-2"), "TRACCAR", "hash");
    VehicleId vehicleId = VehicleId.generate();

    when(deviceRepository.findById(device.id())).thenReturn(Optional.of(device));
    when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(aVehicle(vehicleId)));
    when(deviceRepository.existsActiveForVehicle(vehicleId)).thenReturn(true);

    assertThatThrownBy(() -> useCase.execute(device.id(), vehicleId, ACTOR, "FLEET_MANAGER"))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.DEVICE_ALREADY_ASSIGNED);

    verify(deviceRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }
}
