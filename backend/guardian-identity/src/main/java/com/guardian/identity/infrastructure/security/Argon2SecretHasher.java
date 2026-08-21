package com.guardian.identity.infrastructure.security;

import com.guardian.identity.application.port.SecretHasher;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Argon2id, as SECURITY_ARCHITECTURE.md specifies.
 *
 * <p>Parameters are Spring Security's current defaults rather than hand-picked numbers: they are
 * reviewed as guidance changes, and a locally-tuned cost that nobody revisits ages badly. The
 * encoded output carries its own parameters, so raising them later does not invalidate existing
 * hashes — an OTP issued under the old cost still verifies.
 *
 * <p>{@link Argon2PasswordEncoder#matches} compares in constant time, which is why no comparison is
 * written here. A hand-rolled {@code equals} on the encoded string would return early at the first
 * differing character and leak the correct prefix to anything that can time it — against a
 * six-digit code, that is enough to recover it a digit at a time.
 */
@Component
class Argon2SecretHasher implements SecretHasher {

  private final Argon2PasswordEncoder encoder =
      Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();

  @Override
  public String hash(String rawSecret) {
    return encoder.encode(rawSecret);
  }

  @Override
  public boolean matches(String rawSecret, String hash) {
    return encoder.matches(rawSecret, hash);
  }
}
