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
 * <p>{@code email}, not {@code phone}, is the required identifier — administrative accounts sign
 * in through {@code StaffLoginUseCase} (email and password), never the guardian OTP path. {@code
 * phone} is optional contact information only.
 *
 * <p>{@code initialPassword} exists because no self-service "set your own password" or emailed
 * invite flow is built yet (flagged as a follow-up, not silently assumed away): the creating admin
 * chooses an initial password here and hands it to the new user out of band. It is hashed
 * immediately inside the use case and never stored or logged in the clear.
 *
 * @param schoolId required for a school-scoped role (SCHOOL_ADMIN, PRINCIPAL,
 *     TRANSPORT_MANAGER), null for an organization-scoped one (ORG_ADMIN) — validated against
 *     {@code roleCode} inside the use case (BR-IAM-006).
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
    UUID actorId,
    String actorRole) {

  public CreateAdministrativeUserCommand {
    Objects.requireNonNull(organizationId, "organizationId");
    Objects.requireNonNull(email, "email");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
    Objects.requireNonNull(roleCode, "roleCode");
    Objects.requireNonNull(initialPassword, "initialPassword");
    Objects.requireNonNull(actorId, "actorId");
    Objects.requireNonNull(actorRole, "actorRole");
  }
}
