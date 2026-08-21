package com.guardian.infrastructure.tenant;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantId;
import java.util.Objects;

/**
 * The authenticated principal placed in the security context after authentication.
 *
 * <p>Carries the organization the session belongs to. The tenant is bound to the credential and
 * cannot be influenced by anything the client sends (ADR-0006, BR-TEN-004).
 *
 * <p>Permissions are deliberately absent. They are re-resolved server-side on every request so a
 * revoked role takes effect on the next call rather than at token expiry — holding them here would
 * quietly reintroduce the staleness ADR-0006 rejects.
 */
public record GuardianPrincipal(CurrentActor actor, TenantId tenantId) {

  public GuardianPrincipal {
    Objects.requireNonNull(actor, "actor");
    Objects.requireNonNull(tenantId, "tenantId");
  }
}
