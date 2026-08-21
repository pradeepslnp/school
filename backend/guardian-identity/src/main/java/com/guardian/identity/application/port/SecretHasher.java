package com.guardian.identity.application.port;

/**
 * Hashes and verifies credential secrets.
 *
 * <p>A port rather than a direct call so the algorithm is a deployment decision and can be changed
 * without touching a use case — and so tests do not pay Argon2's deliberate cost on every case.
 *
 * <p>The implementation is Argon2id (guardian-docs/02-system-design/SECURITY_ARCHITECTURE.md). For
 * a six-digit OTP that is not over-engineering: ~20 bits of entropy against a fast hash means the
 * entire space falls in seconds from a stolen database copy, so the work factor is the only thing
 * standing between a leaked backup and every live code in it.
 */
public interface SecretHasher {

  String hash(String rawSecret);

  /**
   * Whether {@code rawSecret} produced {@code hash}.
   *
   * <p>Implementations must compare in constant time. A comparison that returns early on the first
   * differing byte leaks the correct prefix to anything that can measure it, which against a
   * six-digit code is enough to recover it a digit at a time.
   */
  boolean matches(String rawSecret, String hash);
}
