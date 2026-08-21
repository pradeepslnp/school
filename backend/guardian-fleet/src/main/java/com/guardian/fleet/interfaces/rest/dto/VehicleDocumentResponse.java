package com.guardian.fleet.interfaces.rest.dto;

import com.guardian.fleet.domain.VehicleDocument;
import java.time.LocalDate;
import java.util.UUID;

public record VehicleDocumentResponse(
    UUID id,
    UUID vehicleId,
    String documentType,
    String documentNumber,
    LocalDate issuedOn,
    LocalDate expiresOn,
    boolean isMandatory,
    String fileRef) {

  public static VehicleDocumentResponse from(VehicleDocument document) {
    return new VehicleDocumentResponse(
        document.id().value(),
        document.vehicleId().value(),
        document.documentType(),
        document.documentNumber().orElse(null),
        document.issuedOn().orElse(null),
        document.expiresOn(),
        document.mandatory(),
        document.fileRef().orElse(null));
  }
}
