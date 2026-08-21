package com.guardian.fleet.application.command;

import com.guardian.fleet.domain.VehicleId;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.fleet.application.usecase.AddVehicleDocumentUseCase} (FLT-002).
 *
 * <p>{@code documentType} and {@code isMandatory} are validated against the tenant's region profile
 * by the use case, not by this command — the command carries wire input, the use case enforces
 * ADR-0007.
 */
public record AddVehicleDocumentCommand(
    VehicleId vehicleId,
    String documentType,
    String documentNumber,
    LocalDate issuedOn,
    LocalDate expiresOn,
    boolean mandatory,
    String fileRef,
    UUID actorId,
    String actorRole) {

  public AddVehicleDocumentCommand {
    Objects.requireNonNull(vehicleId, "vehicleId");
    Objects.requireNonNull(documentType, "documentType");
    Objects.requireNonNull(expiresOn, "expiresOn");
  }
}
