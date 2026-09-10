package com.guardian.identity.application.command;

import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.identity.application.usecase.CreateAdministrativeUserUseCase}
 * (feature IAM-005/IAM-008, screen A-43).
 *
 * <p>{@code organizationId} names the tenant to create this account in — required even for a
 * school-scoped role, because {@code schoolId} alone does not say which tenant to write under
 * without a cross-module lookup this module deliberately does not make (see the use case's own
 * documentation). The admin console already knows both ids by the time this is called: creating a
 * user always follows picking an organization and, for a school-scoped role, a school within it,
 * the same cascading picker already used by the Students/Drivers/Vehicles/Routes screens.
 *
 * <p>{@code email}, not {@code phone}, is the required identifier — administrative accounts sign in
 * through {@code StaffLoginUseCase} (email and password), never the guardian OTP path. {@code
 * phone} is optional contact information only.
 *
 * <p>{@code deliveryMode} chooses how the account gets a usable sign-in (ADR-0012):
 *
 * <ul>
 *   <li>{@code INVITE} (the default): the account is created {@code PENDING} with no password, and
 *       an invitation link is emailed so the person sets their own. {@code initialPassword} is
 *       ignored and may be null.
 *   <li>{@code PASSWORD}: the creating admin supplies {@code initialPassword} and the account is
 *       active at once — the fallback for onboarding in person or where email is unreliable. The
 *       password is hashed immediately inside the use case and never stored or logged in the clear.
 * </ul>
 *
 * @param schoolId required for a school-scoped role (SCHOOL_ADMIN, PRINCIPAL, TRANSPORT_MANAGER),
 *     null for an organization-scoped one (ORG_ADMIN) — validated against {@code roleCode} inside
 *     the use case (BR-IAM-006).
 * @param initialPassword required only in {@code PASSWORD} mode; the use case enforces that.
 * @param deliveryMode {@code INVITE} or {@code PASSWORD}; null is treated as {@code INVITE}.
 */
public record CreateAdministrativeUserCommand(
    UUID organizationId,
    UUID schoolId,
    String email,
    String phone,
    String firstName,
    String lastName,
    String roleCode,
    String initialPassword,
    String deliveryMode,
    UUID actorId,
    String actorRole) {

  public CreateAdministrativeUserCommand {
    Objects.requireNonNull(organizationId, "organizationId");
    Objects.requireNonNull(email, "email");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
    Objects.requireNonNull(roleCode, "roleCode");
    // initialPassword is intentionally nullable: INVITE mode has no password. PASSWORD mode's
    // requirement is enforced in the use case so it can surface a typed domain error.
    Objects.requireNonNull(actorId, "actorId");
    Objects.requireNonNull(actorRole, "actorRole");
  }

  /**
   * Backward-compatible constructor for callers predating {@code deliveryMode} (ADR-0012): they
   * supplied a password, so this defaults to {@code PASSWORD} mode.
   */
  public CreateAdministrativeUserCommand(
      UUID organizationId,
      UUID schoolId,
      String email,
      String phone,
      String firstName,
      String lastName,
      String roleCode,
      String initialPassword,
      UUID actorId,
      String actorRole) {
    this(
        organizationId,
        schoolId,
        email,
        phone,
        firstName,
        lastName,
        roleCode,
        initialPassword,
        "PASSWORD",
        actorId,
        actorRole);
  }
}
