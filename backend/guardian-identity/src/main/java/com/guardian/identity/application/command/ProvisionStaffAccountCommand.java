package com.guardian.identity.application.command;

import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.identity.application.usecase.ProvisionStaffAccountUseCase} (feature
 * STF-001/MOD-02).
 *
 * <p>No {@code tenantId}: this runs inside the caller's own request, which has already established
 * one — see that use case's documentation.
 */
public record ProvisionStaffAccountCommand(
    String phone,
    String firstName,
    String lastName,
    String roleCode,
    String roleName,
    UUID actorId,
    String actorRole) {

  public ProvisionStaffAccountCommand {
    Objects.requireNonNull(phone, "phone");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
    Objects.requireNonNull(roleCode, "roleCode");
    Objects.requireNonNull(roleName, "roleName");
  }
}
