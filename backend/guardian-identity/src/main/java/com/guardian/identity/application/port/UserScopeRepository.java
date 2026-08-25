package com.guardian.identity.application.port;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserScope;
import java.util.List;

/**
 * Persistence for {@link UserScope} rows (V15__user_scopes.sql).
 *
 * <p>Every method runs inside an already-established tenant context — ordinary row-level
 * security, no {@code SECURITY DEFINER} bypass — matching {@link RoleProvisioningPort}, which this
 * is always called alongside: a role grant with no accompanying scope answers "what" without
 * "which" (BR-IAM-006).
 */
public interface UserScopeRepository {

  /** Every scope currently held by {@code userId}, for presenting on login (BR-IAM-001, affordance only). */
  List<UserScope> findByUser(UserId userId);

  /**
   * Records a new scope for {@code userId}. Additive, not a replace-in-place: matching {@code
   * user_roles}, an existing grant is superseded by adding a new one rather than mutated, which is
   * why this table has no {@code UPDATE} grant (V15__user_scopes.sql).
   */
  void add(TenantId tenantId, UserId userId, UserScope scope);
}
