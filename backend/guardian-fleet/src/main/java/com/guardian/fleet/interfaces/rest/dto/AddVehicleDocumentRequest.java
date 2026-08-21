package com.guardian.fleet.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Wire format for attaching a compliance document to a vehicle (feature FLT-002).
 *
 * @param documentType validated against the tenant's region profile, not a fixed set of values here
 *     (ADR-0007)
 */
public record AddVehicleDocumentRequest(
    @NotBlank String documentType,
    String documentNumber,
    LocalDate issuedOn,
    @NotNull LocalDate expiresOn,
    boolean isMandatory,
    String fileRef) {}
