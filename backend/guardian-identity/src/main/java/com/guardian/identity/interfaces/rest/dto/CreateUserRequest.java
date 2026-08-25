package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Wire format for creating an administrative account (screen A-43). See
 * guardian-docs/04-api/TENANCY_IDENTITY_API.md.
 *
 * <p>Bean validation catches malformed input at the boundary; domain value objects re-check the
 * invariants they own — matching {@code CreateOrganizationRequest}.
 *
 * @param schoolId required for a school-scoped role, null for {@code ORG_ADMIN} — see {@code
 *     CreateAdministrativeUserCommand}.
 * @param initialPassword handed to the new user out of band by the creating admin; no self-service
 *     or emailed invite flow exists yet (flagged, not silently assumed).
 */
public record CreateUserRequest(
    @NotNull UUID organizationId,
    UUID schoolId,
    @NotBlank @Email @Size(max = 255) String email,
    @Size(max = 32) String phone,
    @NotBlank @Size(max = 128) String firstName,
    @NotBlank @Size(max = 128) String lastName,
    @NotBlank String roleCode,
    @NotBlank @Size(min = 8, max = 128) String initialPassword) {}
