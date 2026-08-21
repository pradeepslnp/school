package com.guardian.identity.infrastructure.security;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.AccessTokenVerifier;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.text.ParseException;
import java.time.Instant;
import java.util.Date;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Verifies RS256 access tokens against the published key set.
 *
 * <p>Every check below is one that has been the subject of a real-world JWT vulnerability, which is
 * why none of them is skipped:
 *
 * <ul>
 *   <li><strong>The algorithm comes from the key, not the token.</strong> This only ever constructs
 *       an {@link RSASSAVerifier}, so a token whose header says {@code none} or {@code HS256} fails
 *       to verify rather than being trusted. Selecting a verifier from the token's own {@code alg}
 *       header is the classic algorithm-confusion attack — with {@code HS256} the attacker signs
 *       using the public key, which they have, because it is published.
 *   <li><strong>Issuer and audience are checked.</strong> Without them a validly-signed token
 *       minted for a different service is accepted here.
 *   <li><strong>Expiry is checked explicitly</strong> rather than assumed handled by the library.
 * </ul>
 */
@Component
class NimbusAccessTokenVerifier implements AccessTokenVerifier {

  private static final Logger log = LoggerFactory.getLogger(NimbusAccessTokenVerifier.class);

  private static final String ISSUER = "guardian-platform";
  private static final String AUDIENCE = "guardian-api";

  private final RsaSigningKeys keys;

  NimbusAccessTokenVerifier(RsaSigningKeys keys) {
    this.keys = keys;
  }

  @Override
  public Optional<VerifiedToken> verify(String token) {
    try {
      SignedJWT jwt = SignedJWT.parse(token);

      RSAKey key = keyFor(jwt.getHeader().getKeyID());
      if (key == null) {
        return Optional.empty();
      }

      if (!jwt.verify(new RSASSAVerifier(key))) {
        return Optional.empty();
      }

      JWTClaimsSet claims = jwt.getJWTClaimsSet();

      if (!ISSUER.equals(claims.getIssuer()) || !claims.getAudience().contains(AUDIENCE)) {
        return Optional.empty();
      }

      Date expiry = claims.getExpirationTime();
      if (expiry == null || !Instant.now().isBefore(expiry.toInstant())) {
        return Optional.empty();
      }

      return Optional.of(
          new VerifiedToken(
              UserId.of(UUID.fromString(claims.getSubject())),
              TenantId.fromString(claims.getStringClaim("tenantId")),
              SessionId.of(UUID.fromString(claims.getStringClaim("sessionId"))),
              ClientType.fromWire(claims.getStringClaim("clientType"))));

    } catch (ParseException | JOSEException | IllegalArgumentException | NullPointerException e) {
      // Any malformed token lands here and is refused. Logged at debug: a stream of these is
      // an ordinary consequence of expired clients retrying, not an incident, and logging them
      // at warn would bury real signals.
      log.debug("Rejected an unparseable or unverifiable access token");
      return Optional.empty();
    }
  }

  /**
   * Finds the key the token was signed with.
   *
   * <p>Matched by {@code kid}. During rotation the set holds two, and matching by id is what lets
   * tokens signed by the outgoing key keep working for their remaining minutes rather than every
   * client being signed out the instant a key changes.
   */
  private RSAKey keyFor(String keyId) {
    if (keyId == null) {
      return null;
    }
    JWK found = keys.publicKeys().getKeyByKeyId(keyId);
    return found instanceof RSAKey rsaKey ? rsaKey : null;
  }
}
