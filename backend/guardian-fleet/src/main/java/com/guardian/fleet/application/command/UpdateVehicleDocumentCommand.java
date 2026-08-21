package com.guardian.fleet.application.command;

import com.guardian.fleet.domain.VehicleDocumentId;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.fleet.application.usecase.UpdateVehicleDocumentUseCase} (FLT-002).
 */
public record UpdateVehicleDocumentCommand(
    VehicleDocumentId documentId,
    String documentNumber,
    LocalDate issuedOn,
    LocalDate expiresOn,
    boolean mandatory,
    String fileRef,
    UUID actorId,
    String actorRole) {

  public UpdateVehicleDocumentCommand {
    Objects.requireNonNull(documentId, "documentId");
    Objects.requireNonNull(expiresOn, "expiresOn");
  }
}
