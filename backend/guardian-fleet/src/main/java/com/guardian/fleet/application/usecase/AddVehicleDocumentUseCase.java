package com.guardian.fleet.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.command.AddVehicleDocumentCommand;
import com.guardian.fleet.application.port.VehicleDocumentRepository;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleDocument;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Attaches a compliance document to a vehicle (feature FLT-002).
 *
 * <p>{@code documentType} is validated only for presence here. Full validation against the tenant's
 * region profile (ADR-0007) is MOD-17 Configuration's responsibility once that module exists; this
 * use case does not yet call it, which is why BR-FLEET-002's region-profile aspect remains listed
 * in the traceability baseline as outstanding.
 */
@Service
@BusinessRule("BR-FLEET-002")
public class AddVehicleDocumentUseCase {

  private final VehicleRepository vehicleRepository;
  private final VehicleDocumentRepository documentRepository;
  private final AuditPort auditPort;

  public AddVehicleDocumentUseCase(
      VehicleRepository vehicleRepository,
      VehicleDocumentRepository documentRepository,
      AuditPort auditPort) {
    this.vehicleRepository = vehicleRepository;
    this.documentRepository = documentRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public VehicleDocument execute(AddVehicleDocumentCommand command) {
    TenantId tenantId = TenantContext.require();

    Vehicle vehicle =
        vehicleRepository
            .findById(command.vehicleId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.VEHICLE_NOT_FOUND, "Vehicle", command.vehicleId().value()));

    VehicleDocument document =
        VehicleDocument.create(
            tenantId,
            vehicle.id(),
            command.documentType(),
            command.documentNumber(),
            command.issuedOn(),
            command.expiresOn(),
            command.mandatory(),
            command.fileRef());

    VehicleDocument saved = documentRepository.save(document);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("VEHICLE_DOCUMENT_ADDED")
            .subject("VehicleDocument", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(VehicleDocument document) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("vehicleId", document.vehicleId().toString());
    values.put("documentType", document.documentType());
    values.put("expiresOn", document.expiresOn().toString());
    values.put("mandatory", document.mandatory());
    return values;
  }
}
