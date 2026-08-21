package com.guardian.fleet.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.command.UpdateVehicleDocumentCommand;
import com.guardian.fleet.application.port.VehicleDocumentRepository;
import com.guardian.fleet.domain.VehicleDocument;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Updates a vehicle document's renewable fields — a renewal, not a new artefact (feature FLT-002).
 */
@Service
public class UpdateVehicleDocumentUseCase {

  private final VehicleDocumentRepository documentRepository;
  private final AuditPort auditPort;

  public UpdateVehicleDocumentUseCase(
      VehicleDocumentRepository documentRepository, AuditPort auditPort) {
    this.documentRepository = documentRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public VehicleDocument execute(UpdateVehicleDocumentCommand command) {
    TenantId tenantId = TenantContext.require();

    VehicleDocument existing =
        documentRepository
            .findById(command.documentId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.VEHICLE_DOCUMENT_NOT_FOUND,
                        "VehicleDocument",
                        command.documentId().value()));

    VehicleDocument updated =
        new VehicleDocument(
            existing.id(),
            existing.tenantId(),
            existing.vehicleId(),
            existing.documentType(),
            command.documentNumber(),
            command.issuedOn(),
            command.expiresOn(),
            command.mandatory(),
            command.fileRef(),
            existing.version());

    VehicleDocument saved = documentRepository.save(updated);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("VEHICLE_DOCUMENT_UPDATED")
            .subject("VehicleDocument", saved.id().value())
            .before(Map.of("expiresOn", existing.expiresOn().toString()))
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(VehicleDocument document) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("expiresOn", document.expiresOn().toString());
    values.put("mandatory", document.mandatory());
    return values;
  }
}
