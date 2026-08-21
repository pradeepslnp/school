package com.guardian.identity.application.port;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import java.time.Duration;

/**
 * Mints access tokens.
 *
 * <p>A port because signing is infrastructure — keys, rotation, and JWKS publication have nothing
 * to do with the rules about who may sign in.
 *
 * <p>Note what {@link Claims} does <strong>not</strong> carry: roles, permissions, or scopes. That
 * is BR-IAM-004 and it is the point of ADR-0006. Permissions are re-resolved per request from
 * current assignments, so a permission removed from a role takes effect on the next call rather
 * than whenever the holder's token happens to expire. Adding a {@code roles} claim here would
 * quietly reintroduce exactly the staleness the design rejects.
 */
public interface AccessTokenIssuer {

  IssuedToken issue(Claims claims);

  /**
   * @param tenantId seeds the row-level-security session variable on every request the token makes
   *     (ADR-0001). A token therefore cannot address another tenant.
   * @param sessionId lets a revoked session be recognised before the token expires (BR-IAM-007)
   */
  record Claims(UserId userId, TenantId tenantId, SessionId sessionId, ClientType clientType) {}

  record IssuedToken(String value, Duration lifetime) {}
}
