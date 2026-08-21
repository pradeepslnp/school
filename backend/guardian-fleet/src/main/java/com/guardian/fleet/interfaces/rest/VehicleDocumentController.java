package com.guardian.fleet.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.fleet.application.command.AddVehicleDocumentCommand;
import com.guardian.fleet.application.command.UpdateVehicleDocumentCommand;
import com.guardian.fleet.application.usecase.AddVehicleDocumentUseCase;
import com.guardian.fleet.application.usecase.ListExpiringVehicleDocumentsUseCase;
import com.guardian.fleet.application.usecase.UpdateVehicleDocumentUseCase;
import com.guardian.fleet.domain.VehicleDocument;
import com.guardian.fleet.domain.VehicleDocumentId;
import com.guardian.fleet.domain.VehicleId;
import com.guardian.fleet.interfaces.rest.dto.AddVehicleDocumentRequest;
import com.guardian.fleet.interfaces.rest.dto.UpdateVehicleDocumentRequest;
import com.guardian.fleet.interfaces.rest.dto.VehicleDocumentResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Vehicle document endpoints (feature FLT-002, FLT-003). See
 * guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md.
 */
@RestController
public class VehicleDocumentController {

  private final AddVehicleDocumentUseCase addVehicleDocument;
  private final UpdateVehicleDocumentUseCase updateVehicleDocument;
  private final ListExpiringVehicleDocumentsUseCase listExpiring;

  public VehicleDocumentController(
      AddVehicleDocumentUseCase addVehicleDocument,
      UpdateVehicleDocumentUseCase updateVehicleDocument,
      ListExpiringVehicleDocumentsUseCase listExpiring) {
    this.addVehicleDocument = addVehicleDocument;
    this.updateVehicleDocument = updateVehicleDocument;
    this.listExpiring = listExpiring;
  }

  @PostMapping("/api/v1/vehicles/{vehicleId}/documents")
  @RequiresPermission("PERM-VEHICLE-DOCUMENT-MANAGE")
  public ResponseEntity<VehicleDocumentResponse> add(
      @PathVariable UUID vehicleId,
      @Valid @RequestBody AddVehicleDocumentRequest request,
      CurrentActor actor) {

    AddVehicleDocumentCommand command =
        new AddVehicleDocumentCommand(
            VehicleId.of(vehicleId),
            request.documentType(),
            request.documentNumber(),
            request.issuedOn(),
            request.expiresOn(),
            request.isMandatory(),
            request.fileRef(),
            actor.userId(),
            actor.role());

    VehicleDocument created = addVehicleDocument.execute(command);

    return ResponseEntity.created(
            URI.create("/api/v1/vehicles/" + vehicleId + "/documents/" + created.id()))
        .body(VehicleDocumentResponse.from(created));
  }

  @PatchMapping("/api/v1/vehicles/{vehicleId}/documents/{documentId}")
  @RequiresPermission("PERM-VEHICLE-DOCUMENT-MANAGE")
  public VehicleDocumentResponse update(
      @PathVariable UUID vehicleId,
      @PathVariable UUID documentId,
      @Valid @RequestBody UpdateVehicleDocumentRequest request,
      CurrentActor actor) {

    UpdateVehicleDocumentCommand command =
        new UpdateVehicleDocumentCommand(
            VehicleDocumentId.of(documentId),
            request.documentNumber(),
            request.issuedOn(),
            request.expiresOn(),
            request.isMandatory(),
            request.fileRef(),
            actor.userId(),
            actor.role());

    return VehicleDocumentResponse.from(updateVehicleDocument.execute(command));
  }

  /** Feeds the manual "what's expiring" view ahead of the daily warning job (BR-FLEET-003). */
  @GetMapping("/api/v1/vehicles/documents/expiring")
  @RequiresPermission("PERM-VEHICLE-VIEW")
  public List<VehicleDocumentResponse> expiring(
      @RequestParam(name = "withinDays", required = false, defaultValue = "30") int withinDays) {
    return listExpiring.withinDays(withinDays).stream().map(VehicleDocumentResponse::from).toList();
  }
}
