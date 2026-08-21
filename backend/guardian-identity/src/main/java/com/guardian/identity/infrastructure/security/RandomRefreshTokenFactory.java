package com.guardian.identity.infrastructure.security;

import com.guardian.identity.application.port.RefreshTokenFactory;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import org.springframework.stereotype.Component;

/**
 * Opaque refresh tokens: 256 bits from {@link SecureRandom}, stored as a SHA-256 digest.
 *
 * <p>256 bits is not guesswork — it is the point at which brute force stops being a consideration
 * at all, and the token is never typed by a human, so length costs nothing.
 *
 * <p>SHA-256 rather than Argon2 for the stored form, unlike {@link Argon2SecretHasher}. The input
 * here is already uniformly random, so there is no dictionary to run and no work factor to buy;
 * adding one would only slow every refresh. The reasoning does not transfer between the two, which
 * is why they are separate ports rather than one "hasher".
 */
@Component
class RandomRefreshTokenFactory implements RefreshTokenFactory {

  private static final int TOKEN_BYTES = 32;

  private final SecureRandom random = new SecureRandom();

  @Override
  public String generate() {
    byte[] bytes = new byte[TOKEN_BYTES];
    random.nextBytes(bytes);
    // URL-safe and unpadded so the value survives being put in a header, a query string, or a
    // JSON body without re-encoding.
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
  }

  @Override
  public String hash(String rawToken) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hashed = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
      return Base64.getUrlEncoder().withoutPadding().encodeToString(hashed);
    } catch (NoSuchAlgorithmException e) {
      // SHA-256 is required of every JVM. If it is genuinely absent the platform cannot
      // authenticate anyone, and continuing would mean storing tokens in some weaker form.
      throw new IllegalStateException("SHA-256 unavailable", e);
    }
  }
}
