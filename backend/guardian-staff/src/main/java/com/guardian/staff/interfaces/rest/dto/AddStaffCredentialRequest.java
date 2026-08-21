package com.guardian.staff.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Wire format for attaching a licence or certification to a staff member (feature STF-002).
 *
 * @param credentialType validated against the tenant's region profile, not a fixed set of values
 *     here (ADR-0007)
 */
public record AddStaffCredentialRequest(
    @NotBlank String credentialType,
    String credentialNumber,
    String credentialClass,
    LocalDate issuedOn,
    @NotNull LocalDate expiresOn,
    boolean isMandatory,
    String fileRef) {}
