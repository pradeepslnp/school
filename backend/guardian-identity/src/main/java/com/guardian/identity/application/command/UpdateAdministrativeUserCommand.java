package com.guardian.identity.application.command;

import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.identity.application.usecase.UpdateAdministrativeUserUseCase}
 * (feature IAM-005, screen A-43).
 *
 * <p>Name and locale only, deliberately. Changing a user's role or scope after creation is a
 * bigger, separate concern (it re-opens the assigner/assignable-role check {@code
 * CreateAdministrativeUserUseCase} makes at creation time) and is not built yet — the interim path
 * for "this person needs a different role" is deactivating this account and creating the new one,
 * same as this codebase already does for a corrected email in a few other places rather than
 * pretending an edit form can silently launder authorisation-relevant fields.
 */
public record UpdateAdministrativeUserCommand(
    UUID organizationId,
    UUID userId,
    String firstName,
    String lastName,
    String preferredLocale,
    UUID actorId,
    String actorRole) {

  public UpdateAdministrativeUserCommand {
    Objects.requireNonNull(organizationId, "organizationId");
    Objects.requireNonNull(userId, "userId");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
    Objects.requireNonNull(preferredLocale, "preferredLocale");
  }
}
