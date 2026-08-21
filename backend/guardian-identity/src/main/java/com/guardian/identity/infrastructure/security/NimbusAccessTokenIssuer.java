package com.guardian.identity.infrastructure.security;

import com.guardian.identity.application.port.AccessTokenIssuer;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Signs access tokens with RS256 (ADR-0006).
 *
 * <p>Asymmetric rather than HMAC on purpose: verification needs only the public key, so ingestion,
 * worker, and any future service can verify a token without holding anything that could mint one.
 * With a shared secret, every verifier is also an issuer.
 */
@Component
class NimbusAccessTokenIssuer implements AccessTokenIssuer {

  /**
   * Fifteen minutes, per ADR-0006.
   *
   * <p>Short because an access token cannot be revoked — only outlived. It is the upper bound on
   * how long a revoked session keeps working (BR-IAM-007), which is why the number is stated in the
   * API contract rather than tuned quietly.
   */
  private static final Duration LIFETIME = Duration.ofMinutes(15);

  private static final String ISSUER = "guardian-platform";
  private static final String AUDIENCE = "guardian-api";

  private final RsaSigningKeys keys;

  NimbusAccessTokenIssuer(RsaSigningKeys keys) {
    this.keys = keys;
  }

  @Override
  public IssuedToken issue(Claims claims) {
    Instant now = Instant.now();
    Instant expiry = now.plus(LIFETIME);

    JWTClaimsSet claimsSet =
        new JWTClaimsSet.Builder()
            .subject(claims.userId().value().toString())
            .issuer(ISSUER)
            .audience(AUDIENCE)
            // Seeds the row-level-security session variable on every request this token makes
            // (ADR-0001). A token therefore cannot address another tenant, whatever it asks for.
            .claim("tenantId", claims.tenantId().value().toString())
            // Lets a revoked session be recognised before the token expires (BR-IAM-007).
            .claim("sessionId", claims.sessionId().value().toString())
            .claim("clientType", claims.clientType().name())
            .issueTime(Date.from(now))
            .expirationTime(Date.from(expiry))
            .jwtID(UUID.randomUUID().toString())
            .build();
    // No roles, permissions, or scopes: BR-IAM-004. They are resolved per request, so a
    // revoked role takes effect on the next call rather than at token expiry.

    try {
      SignedJWT jwt =
          new SignedJWT(
              new JWSHeader.Builder(JWSAlgorithm.RS256)
                  // The key id is what makes rotation work — a verifier picks the matching key
                  // out of the JWKS instead of guessing.
                  .keyID(keys.signingKey().getKeyID())
                  .build(),
              claimsSet);

      jwt.sign(new RSASSASigner(keys.signingKey().toPrivateKey()));

      return new IssuedToken(jwt.serialize(), LIFETIME);
    } catch (JOSEException e) {
      // Signing cannot be recovered from and must never fall back to an unsigned token.
      throw new IllegalStateException("Could not sign access token", e);
    }
  }
}
