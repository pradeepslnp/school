package com.guardian.fleet.application.port;

/**
 * Hashes and verifies device credential secrets.
 *
 * <p>A port rather than a direct call so the algorithm is a deployment decision, and so tests do
 * not pay the deliberate cost of a slow hash on every case (mirrors {@code guardian-identity}'s
 * {@code SecretHasher}, guardian-docs/02-system-design/SECURITY_ARCHITECTURE.md).
 */
public interface DeviceCredentialHasher {

  String hash(String rawSecret);

  /** Implementations must compare in constant time. */
  boolean matches(String rawSecret, String hash);
}
