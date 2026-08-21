package com.guardian.tenancy.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for editing an organization. No {@code code}: it is immutable once the organization
 * exists (BR-TEN-007), and has no endpoint to change it.
 */
public record UpdateOrganizationRequest(
    @NotBlank @Size(max = 255) String name,
    @NotBlank @Size(max = 32) String regionProfileCode,
    @Email @Size(max = 255) String contactEmail,
    @Size(max = 32) String contactPhone) {}
