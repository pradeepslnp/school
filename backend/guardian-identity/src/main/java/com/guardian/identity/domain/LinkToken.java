package com.guardian.identity.domain;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Objects;

/**
 * The random secret carried in an invitation or password-reset link (ADR-0012).
 *
 * <p>256 bits from {@link SecureRandom}, URL-safe Base64 without padding so it drops straight into
 * a query string. Unlike an {@link OtpCode} — six digits, ~20 bits, only safe because a short
 * lifetime and an attempt limit hold the space closed — a link token's entropy <em>is</em> the
 * control: brute-forcing 256 bits is infeasible, which is why these carry no per-token attempt
 * lockout.
 *
 * <p>Because the entropy is this high, the stored form is a plain {@code SHA-256} (see {@code
 * TokenHasher}), not a salted password hash — deterministic, so the token can be looked up by its
 * hash, and still useless to anyone who reads the table.
 *
 * <p>The raw value exists only in memory and in the one email that carries it; it is never logged
 * in production and never persisted in the clear.
 */
public record LinkToken(String value) {

  private static final SecureRandom RANDOM = new SecureRandom();

  /** 32 bytes = 256 bits. */
  private static final int ENTROPY_BYTES = 32;

  public LinkToken {
    Objects.requireNonNull(value, "value");
    if (value.isBlank()) {
      throw new IllegalArgumentException("token must not be blank");
    }
  }

  /** Generates a fresh, unguessable token. */
  public static LinkToken generate() {
    byte[] bytes = new byte[ENTROPY_BYTES];
    RANDOM.nextBytes(bytes);
    return new LinkToken(Base64.getUrlEncoder().withoutPadding().encodeToString(bytes));
  }

  /** Parses a token presented by a caller, trimming incidental whitespace. */
  public static LinkToken of(String raw) {
    Objects.requireNonNull(raw, "raw");
    return new LinkToken(raw.trim());
  }

  /** Never renders the value — a link token in a log is a credential in a log. */
  @Override
  public String toString() {
    return "LinkToken[***]";
  }
}
