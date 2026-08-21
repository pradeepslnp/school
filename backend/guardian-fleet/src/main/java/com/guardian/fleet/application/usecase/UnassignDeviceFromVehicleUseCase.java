package com.guardian.fleet.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.port.DeviceRepository;
import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceId;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UnassignDeviceFromVehicleUseCase {

  private final DeviceRepository deviceRepository;
  private final AuditPort auditPort;

  public UnassignDeviceFromVehicleUseCase(DeviceRepository deviceRepository, AuditPort auditPort) {
    this.deviceRepository = deviceRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public Device execute(DeviceId deviceId, UUID actorId, String actorRole) {
    TenantId tenantId = TenantContext.require();

    Device device =
        deviceRepository
            .findById(deviceId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.DEVICE_NOT_REGISTERED, "Device", deviceId.value()));

    Device unassigned = deviceRepository.save(device.unassign());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("DEVICE_UNASSIGNED")
            .subject("Device", unassigned.id().value())
            .before(Map.of("vehicleId", device.vehicleId().map(Object::toString).orElse(null)))
            .build());

    return unassigned;
  }
}
