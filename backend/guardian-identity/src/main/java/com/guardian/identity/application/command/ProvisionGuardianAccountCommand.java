package com.guardian.identity.application.command;

import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.identity.application.usecase.ProvisionGuardianAccountUseCase}
 * (features GRD-001 / IAM-002).
 *
 * <p>Deliberately parallel to {@code ProvisionStaffAccountCommand} rather than shared with it: a
 * guardian account and a staff account are provisioned by two separate use cases so each writes its
 * own, accurate audit action, and reusing one command for both would blur that boundary. There is
 * no {@code roleCode} here because a guardian account always grants exactly the {@code GUARDIAN}
 * role — there is nothing for the caller to choose.
 *
 * <p>No {@code tenantId}: this runs inside the caller's own already-established request.
 */
public record ProvisionGuardianAccountCommand(
    String phone, String firstName, String lastName, UUID actorId, String actorRole) {

  public ProvisionGuardianAccountCommand {
    Objects.requireNonNull(phone, "phone");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
  }
}
