package com.guardian.infrastructure.guardian;

import com.guardian.guardian.application.port.GuardianAccountProvisioningPort;
import com.guardian.identity.application.command.ProvisionGuardianAccountCommand;
import com.guardian.identity.application.usecase.ProvisionGuardianAccountUseCase;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Implements guardian-guardian's {@link GuardianAccountProvisioningPort} by calling
 * guardian-identity's {@link ProvisionGuardianAccountUseCase} — this is the one place in the backend
 * allowed to depend on both modules, which is exactly why the port lives in guardian-guardian and
 * the adapter lives here. See the port's own documentation, and {@code
 * StaffAccountProvisioningAdapter} for the identical shape on the staff side.
 */
@Component
class GuardianAccountProvisioningAdapter implements GuardianAccountProvisioningPort {

  private final ProvisionGuardianAccountUseCase provisionGuardianAccount;

  GuardianAccountProvisioningAdapter(ProvisionGuardianAccountUseCase provisionGuardianAccount) {
    this.provisionGuardianAccount = provisionGuardianAccount;
  }

  @Override
  public UUID provision(
      String phone, String firstName, String lastName, UUID actorId, String actorRole) {
    return provisionGuardianAccount
        .execute(
            new ProvisionGuardianAccountCommand(phone, firstName, lastName, actorId, actorRole))
        .value();
  }
}
