package com.guardian.identity.application.port;

/**
 * Hashes a high-entropy link token for storage and lookup (ADR-0012).
 *
 * <p>Deliberately <em>not</em> {@link SecretHasher}. That port is salted Argon2id, correct for
 * low-entropy secrets (a password, a six-digit OTP) where the work factor is the only thing between
 * a leaked backup and every live credential in it — but salted and therefore not something you can
 * look a value up by.
 *
 * <p>A {@link com.guardian.identity.domain.LinkToken} is 256 bits of randomness. Against that, a
 * fast unsalted {@code SHA-256} is safe (there is nothing to brute-force) <strong>and</strong>
 * deterministic, so the public accept/reset endpoints — which hold the token but not the user id —
 * can resolve the account by hashing the token and matching. Using Argon2 here would make that
 * lookup impossible; using this for a password would be a security hole. The two are not
 * interchangeable, and that is the whole point of keeping them as separate ports.
 */
public interface TokenHasher {

  /** The deterministic hash of {@code rawToken}, suitable for storage and equality lookup. */
  String hash(String rawToken);
}
