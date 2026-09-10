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
 * @param initialPassword required only in {@code PASSWORD} delivery mode; omitted in {@code INVITE}
 *     mode, where the new user sets their own via the emailed link (ADR-0012). Its strength is
 *     enforced server-side by {@code PasswordPolicy}, so only a coarse max length is checked here.
 * @param deliveryMode {@code INVITE} (default) or {@code PASSWORD}; null is treated as {@code
 *     INVITE}.
 */
public record CreateUserRequest(
    @NotNull UUID organizationId,
    UUID schoolId,
    @NotBlank @Email @Size(max = 255) String email,
    @Size(max = 32) String phone,
    @NotBlank @Size(max = 128) String firstName,
    @NotBlank @Size(max = 128) String lastName,
    @NotBlank String roleCode,
    @Size(max = 128) String initialPassword,
    String deliveryMode) {

  /**
   * Backward-compatible constructor for callers predating {@code deliveryMode} (ADR-0012): a
   * supplied password means {@code PASSWORD} mode.
   */
  public CreateUserRequest(
      UUID organizationId,
      UUID schoolId,
      String email,
      String phone,
      String firstName,
      String lastName,
      String roleCode,
      String initialPassword) {
    this(
        organizationId,
        schoolId,
        email,
        phone,
        firstName,
        lastName,
        roleCode,
        initialPassword,
        "PASSWORD");
  }
}
