package com.guardian.fleet.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.command.UpdateVehicleCommand;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.Vehicle;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Updates a vehicle's mutable details (feature FLT-001).
 *
 * <p>Registration number and vehicle type are not editable here — a registration change is a
 * different vehicle, and a type change would silently invalidate credential-class checks that
 * reference it (BR-STAFF-001). Both require deactivating this record and registering anew.
 */
@Service
public class UpdateVehicleUseCase {

  private final VehicleRepository vehicleRepository;
  private final AuditPort auditPort;

  public UpdateVehicleUseCase(VehicleRepository vehicleRepository, AuditPort auditPort) {
    this.vehicleRepository = vehicleRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public Vehicle execute(UpdateVehicleCommand command) {
    TenantId tenantId = TenantContext.require();

    Vehicle existing =
        vehicleRepository
            .findById(command.vehicleId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.VEHICLE_NOT_FOUND, "Vehicle", command.vehicleId().value()));

    Vehicle updated =
        existing.updateDetails(
            command.displayName(), command.seatingCapacity(), command.vendorName());
    Vehicle saved = vehicleRepository.save(updated);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("VEHICLE_UPDATED")
            .subject("Vehicle", saved.id().value())
            .before(describe(existing))
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(Vehicle vehicle) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("displayName", vehicle.displayName());
    values.put("seatingCapacity", vehicle.seatingCapacity().seats());
    values.put("vendorName", vehicle.vendorName().orElse(null));
    return values;
  }
}
