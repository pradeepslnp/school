package com.guardian.fleet.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record UpdateVehicleDocumentRequest(
    String documentNumber,
    LocalDate issuedOn,
    @NotNull LocalDate expiresOn,
    boolean isMandatory,
    String fileRef) {}
