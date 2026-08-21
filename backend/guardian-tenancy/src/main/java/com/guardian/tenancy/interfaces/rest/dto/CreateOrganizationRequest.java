package com.guardian.tenancy.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for creating an organization. See TENANCY_IDENTITY_API.md.
 *
 * <p>Bean validation catches malformed input at the boundary; domain value objects re-check the
 * invariants they own — the duplication is intentional, matching {@code CreateSchoolRequest}.
 *
 * @param regionProfileCode supplies defaults for phone formats, required vehicle documents, staff
 *     credential types, address format, and retention (ADR-0007). Required, never defaulted —
 *     guessing one would apply the wrong region's rules until someone noticed.
 */
public record CreateOrganizationRequest(
    @NotBlank @Size(max = 32) String code,
    @NotBlank @Size(max = 255) String name,
    @NotBlank @Size(max = 32) String regionProfileCode,
    @Email @Size(max = 255) String contactEmail,
    @Size(max = 32) String contactPhone) {}
