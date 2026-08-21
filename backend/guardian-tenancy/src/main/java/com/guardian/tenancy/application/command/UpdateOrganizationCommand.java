package com.guardian.tenancy.application.command;

import com.guardian.tenancy.domain.OrganizationId;
import java.util.Objects;
import java.util.UUID;

/** Input to {@link com.guardian.tenancy.application.usecase.UpdateOrganizationUseCase}. */
public record UpdateOrganizationCommand(
    OrganizationId id,
    String name,
    String regionProfileCode,
    String contactEmail,
    String contactPhone,
    UUID actorId,
    String actorRole) {

  public UpdateOrganizationCommand {
    Objects.requireNonNull(id, "id");
    Objects.requireNonNull(name, "name");
    Objects.requireNonNull(regionProfileCode, "regionProfileCode");
  }
}
