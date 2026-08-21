package com.guardian.tenancy.application.command;

import com.guardian.tenancy.domain.OrganizationCode;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.tenancy.application.usecase.CreateOrganizationUseCase}.
 *
 * <p>Already parsed into domain types — the interface layer converts the wire string into {@link
 * OrganizationCode}, so a malformed code fails at the boundary rather than inside the use case.
 */
public record CreateOrganizationCommand(
    OrganizationCode code,
    String name,
    String regionProfileCode,
    String contactEmail,
    String contactPhone,
    UUID actorId,
    String actorRole) {

  public CreateOrganizationCommand {
    Objects.requireNonNull(code, "code");
    Objects.requireNonNull(name, "name");
    Objects.requireNonNull(regionProfileCode, "regionProfileCode");
  }
}
