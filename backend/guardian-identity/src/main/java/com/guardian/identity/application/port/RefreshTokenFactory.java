package com.guardian.identity.application.port;

/**
 * Produces opaque refresh tokens and the hashes stored against them.
 *
 * <p>Refresh tokens are random, not signed: a JWT refresh token would carry its own validity and so
 * could not be revoked before expiry, which is precisely what BR-IAM-007 and BR-IAM-009 require.
 * The server's copy is the authority, and the server's copy is a hash.
 *
 * <p>{@link #hash} is a plain digest rather than a work-factor hash, deliberately. The input is
 * already high-entropy random, so there is nothing to brute-force; a slow hash here would only add
 * latency to every refresh. That reasoning does <em>not</em> transfer to {@link SecretHasher},
 * whose input is six digits a human chose to type.
 */
public interface RefreshTokenFactory {

  /** A fresh token. Returned to the client once and never stored in this form. */
  String generate();

  /** The value stored in {@code sessions.refresh_token_hash}. */
  String hash(String rawToken);
}
