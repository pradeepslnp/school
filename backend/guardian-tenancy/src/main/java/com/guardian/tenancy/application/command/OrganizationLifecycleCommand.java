package com.guardian.tenancy.application.command;

import com.guardian.tenancy.domain.OrganizationId;
import java.util.Objects;
import java.util.UUID;

/**
 * Input shared by {@link com.guardian.tenancy.application.usecase.SuspendOrganizationUseCase} and
 * {@link com.guardian.tenancy.application.usecase.ReactivateOrganizationUseCase} (BR-TEN-006) —
 * both need only the target organization and who is acting, so one command serves both rather
 * than two identical records.
 */
public record OrganizationLifecycleCommand(OrganizationId id, UUID actorId, String actorRole) {

  public OrganizationLifecycleCommand {
    Objects.requireNonNull(id, "id");
    Objects.requireNonNull(actorId, "actorId");
    Objects.requireNonNull(actorRole, "actorRole");
  }
}
