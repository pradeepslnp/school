package com.guardian.identity.infrastructure.security;

import com.guardian.identity.application.port.TokenHasher;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import org.springframework.stereotype.Component;

/**
 * {@link TokenHasher} as an unsalted SHA-256, rendered lowercase hex.
 *
 * <p>Deterministic on purpose — the public accept/reset endpoints look a token up by this hash. Safe
 * despite being fast because the input is 256 bits of randomness ({@code LinkToken}); see the port's
 * documentation for why this is correct here and Argon2 is not.
 */
@Component
class Sha256TokenHasher implements TokenHasher {

  @Override
  public String hash(String rawToken) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hashed = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(hashed);
    } catch (NoSuchAlgorithmException e) {
      // SHA-256 is mandated by the JLS on every conformant JVM; its absence is not a runtime
      // condition to recover from.
      throw new IllegalStateException("SHA-256 is unavailable on this JVM", e);
    }
  }
}
