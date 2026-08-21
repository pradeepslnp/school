package com.guardian.identity.application.port;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.UserId;

/**
 * Grants a system role within a tenant, creating the role row itself the first time it is needed
 * (feature STF-001/MOD-02; full role management is IAM-005, not yet built — see this port's
 * narrower scope below).
 *
 * <p>{@code roles} and {@code user_roles} have no domain aggregate of their own in this module:
 * {@link UserRepository#roleCodesOf} already treats them as a read-only projection, and nothing
 * here needs more than "does this row exist, and if not, create it" — a much narrower job than
 * IAM-005's actual role-management screen (create/edit/delete arbitrary roles, assign permissions
 * to them) will eventually be. This port exists only so a staff member's account has the one system
 * role their {@code staffType} implies the moment their login is provisioned.
 */
public interface RoleProvisioningPort {

  /**
   * The role for {@code code} in this tenant, creating it (as a system role) if it does not exist.
   */
  RoleId findOrCreateSystemRole(TenantId tenantId, String code, String name);

  /** Grants {@code roleId} to {@code userId}, doing nothing if it is already held. */
  void grantIfMissing(TenantId tenantId, UserId userId, RoleId roleId);
}
