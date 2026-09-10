package com.guardian.identity.application.command;

import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.identity.application.usecase.ChangeAdministrativeUserRoleUseCase}
 * (feature IAM-005, IAM-007; screen A-43, {@code PERM-ROLE-MANAGE}).
 *
 * <p>Role and scope move together, the same pairing {@code CreateAdministrativeUserCommand} makes:
 * a {@code SCHOOL_ADMIN} <em>is</em> a school-scoped role, so "change to SCHOOL_ADMIN" without
 * saying which school is not a complete instruction. {@code schoolId} is required when {@code
 * roleCode} is school-scoped and must be absent otherwise.
 */
public record ChangeAdministrativeUserRoleCommand(
    UUID organizationId,
    UUID userId,
    String roleCode,
    UUID schoolId,
    UUID actorId,
    String actorRole) {

  public ChangeAdministrativeUserRoleCommand {
    Objects.requireNonNull(organizationId, "organizationId");
    Objects.requireNonNull(userId, "userId");
    Objects.requireNonNull(roleCode, "roleCode");
    Objects.requireNonNull(actorId, "actorId");
    Objects.requireNonNull(actorRole, "actorRole");
  }
}
