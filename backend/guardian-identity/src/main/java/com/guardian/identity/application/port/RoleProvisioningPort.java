package com.guardian.identity.application.port;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.UserId;

/**
 * Grants and revokes a <em>system</em> role within a tenant, creating the role row itself the first
 * time it is needed (features STF-001, IAM-005).
 *
 * <p>{@code roles} and {@code user_roles} have no domain aggregate of their own in this module:
 * {@link UserRepository#roleCodesOf} already treats them as a read-only projection, and the
 * operations here are all "does this row exist — create it, grant it, or remove it". That is the
 * whole of role <em>assignment</em> (IAM-005). Role <em>definition</em> — a tenant creating its own
 * roles and picking their permissions (IAM-006) — is a separate, still-unbuilt concern that would
 * write {@code role_permissions}; the nine system templates deliberately do not, resolving their
 * grants from {@code SystemRolePermissions} in code instead.
 */
public interface RoleProvisioningPort {

  /**
   * The role for {@code code} in this tenant, creating it (as a system role) if it does not exist.
   */
  RoleId findOrCreateSystemRole(TenantId tenantId, String code, String name);

  /** Grants {@code roleId} to {@code userId}, doing nothing if it is already held. */
  void grantIfMissing(TenantId tenantId, UserId userId, RoleId roleId);

  /**
   * Removes the grant of the system role {@code code} from {@code userId}, if held.
   *
   * <p>Used when the Users screen changes an administrator's role (IAM-005): the old administrative
   * grant is removed in the same transaction the new one is added, so an account never briefly
   * holds two administrative roles or none. Deletes the {@code user_roles} row rather than marking
   * it — a role a person no longer holds is not history the way a revoked session is; {@link
   * com.guardian.common.audit.AuditRecord} on the change is what stays.
   *
   * @return whether a row was removed
   */
  boolean revokeSystemRole(TenantId tenantId, UserId userId, String code);
}
