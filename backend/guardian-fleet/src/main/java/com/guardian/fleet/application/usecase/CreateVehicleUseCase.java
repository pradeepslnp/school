package com.guardian.fleet.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.command.CreateVehicleCommand;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.Vehicle;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Registers a vehicle (feature FLT-001).
 *
 * <p>One class, one operation. Constructor injection only, all dependencies final
 * (guardian-docs/ENGINEERING_PRINCIPLES.md §5).
 */
@Service
@BusinessRule({"BR-FLEET-001", "BR-AUD-002"})
public class CreateVehicleUseCase {

  private final VehicleRepository vehicleRepository;
  private final AuditPort auditPort;

  public CreateVehicleUseCase(VehicleRepository vehicleRepository, AuditPort auditPort) {
    this.vehicleRepository = vehicleRepository;
    this.auditPort = auditPort;
  }

  /**
   * @throws BusinessRuleViolationException if the registration number is already used within the
   *     organization (BR-FLEET-001)
   */
  @Transactional
  public Vehicle execute(CreateVehicleCommand command) {
    TenantId tenantId = TenantContext.require();

    // BR-FLEET-001: a registration number is unique within its organization. tenant_id IS the
    // organization (ADR-0002), so the repository's uniqueness check is implicitly scoped by RLS.
    if (vehicleRepository.existsByRegistrationNo(command.registrationNo())) {
      throw new BusinessRuleViolationException(
          ErrorCode.VEHICLE_REGISTRATION_EXISTS,
          "BR-FLEET-001",
          Map.of("registrationNo", command.registrationNo().value()));
    }

    Vehicle vehicle =
        Vehicle.create(
            tenantId,
            command.schoolId(),
            command.registrationNo(),
            command.displayName(),
            command.vehicleType(),
            command.seatingCapacity(),
            command.vendorName());

    Vehicle saved = vehicleRepository.save(vehicle);

    // BR-AUD-002: the audit write shares this transaction. If it fails, the vehicle is not
    // created — the platform refuses an operation rather than performing it unrecorded.
    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("VEHICLE_REGISTERED")
            .subject("Vehicle", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(Vehicle vehicle) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("registrationNo", vehicle.registrationNo().value());
    values.put("displayName", vehicle.displayName());
    values.put("vehicleType", vehicle.vehicleType().name());
    values.put("seatingCapacity", vehicle.seatingCapacity().seats());
    values.put("status", vehicle.status().name());
    return values;
  }
}
