package com.guardian.staff.application.command;

import com.guardian.staff.domain.StaffId;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.staff.application.usecase.AddStaffCredentialUseCase} (STF-002).
 *
 * <p>{@code credentialType} and {@code credentialClass} are validated against the tenant's region
 * profile by the use case, not by this command — the command carries wire input, the use case
 * enforces ADR-0007.
 */
public record AddStaffCredentialCommand(
    StaffId staffId,
    String credentialType,
    String credentialNumber,
    String credentialClass,
    LocalDate issuedOn,
    LocalDate expiresOn,
    boolean mandatory,
    String fileRef,
    UUID actorId,
    String actorRole) {

  public AddStaffCredentialCommand {
    Objects.requireNonNull(staffId, "staffId");
    Objects.requireNonNull(credentialType, "credentialType");
    Objects.requireNonNull(expiresOn, "expiresOn");
  }
}
