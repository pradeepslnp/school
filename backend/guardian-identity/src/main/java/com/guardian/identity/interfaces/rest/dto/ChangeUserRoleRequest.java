package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * Wire format for changing an administrator's role and scope (screen A-43, {@code
 * PERM-ROLE-MANAGE}).
 *
 * <p>{@code schoolId} is required when {@code roleCode} is a school-scoped role ({@code
 * SCHOOL_ADMIN}, {@code PRINCIPAL}, {@code TRANSPORT_MANAGER}) and must be omitted for {@code
 * ORG_ADMIN} — the use case enforces the pairing and answers {@code
 * USER_SCOPE_NOT_PERMITTED_FOR_ROLE} when it is wrong.
 */
public record ChangeUserRoleRequest(
    @NotNull UUID organizationId, @NotBlank String roleCode, UUID schoolId) {}
