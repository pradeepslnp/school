package com.guardian.identity.application.port;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import java.util.Optional;

/**
 * Verifies an access token presented on a request.
 *
 * <p>Returns an {@link Optional} rather than throwing. Every rejection reason — bad signature,
 * expired, wrong issuer, malformed, unknown key — produces the same {@code 401}, so distinguishing
 * them in the type system would only invite a caller to report the difference to whoever sent the
 * token.
 */
public interface AccessTokenVerifier {

  /** The claims of a token whose signature, issuer, audience, and expiry all check out. */
  Optional<VerifiedToken> verify(String token);

  /**
   * @param tenantId taken from the token and used to seed row-level security. It is bound to the
   *     credential at issue and cannot be influenced by anything else the client sends
   *     (BR-TEN-004).
   */
  record VerifiedToken(
      UserId userId, TenantId tenantId, SessionId sessionId, ClientType clientType) {}
}
