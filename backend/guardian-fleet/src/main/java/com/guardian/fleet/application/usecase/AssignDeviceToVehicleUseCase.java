package com.guardian.fleet.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.port.DeviceRepository;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceId;
import com.guardian.fleet.domain.VehicleId;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Assigns a device to a vehicle (feature FLT-004).
 *
 * <p>BR-FLEET-004 🔴: a vehicle has at most one active GPS device at a time. Two devices reporting
 * for one bus would produce contradictory positions. Enforced twice: here, so the failure is a
 * named {@code 409 DEVICE_ALREADY_ASSIGNED} rather than a raw constraint error, and structurally by
 * the database's {@code uq_devices_vehicle_active} partial unique index, so a race between two
 * concurrent assignments still cannot succeed.
 */
@Service
@BusinessRule({"BR-FLEET-004", "BR-AUD-002"})
public class AssignDeviceToVehicleUseCase {

  private final DeviceRepository deviceRepository;
  private final VehicleRepository vehicleRepository;
  private final AuditPort auditPort;

  public AssignDeviceToVehicleUseCase(
      DeviceRepository deviceRepository, VehicleRepository vehicleRepository, AuditPort auditPort) {
    this.deviceRepository = deviceRepository;
    this.vehicleRepository = vehicleRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public Device execute(DeviceId deviceId, VehicleId vehicleId, UUID actorId, String actorRole) {
    TenantId tenantId = TenantContext.require();

    Device device =
        deviceRepository
            .findById(deviceId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.DEVICE_NOT_REGISTERED, "Device", deviceId.value()));

    vehicleRepository
        .findById(vehicleId)
        .orElseThrow(
            () ->
                new ResourceNotFoundException(
                    ErrorCode.VEHICLE_NOT_FOUND, "Vehicle", vehicleId.value()));

    if (deviceRepository.existsActiveForVehicle(vehicleId)) {
      throw new BusinessRuleViolationException(
          ErrorCode.DEVICE_ALREADY_ASSIGNED,
          "BR-FLEET-004",
          Map.of("vehicleId", vehicleId.toString()));
    }

    Device assigned = deviceRepository.save(device.assignTo(vehicleId));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("DEVICE_ASSIGNED")
            .subject("Device", assigned.id().value())
            .after(Map.of("vehicleId", vehicleId.toString()))
            .build());

    return assigned;
  }
}
