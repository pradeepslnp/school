package com.guardian.identity.domain;

import java.time.Duration;

/**
 * What an {@link AccountToken} is for, and how long it lives (ADR-0012).
 *
 * <p>Two link-token kinds, deliberately distinct rather than one "token" with a caller-supplied
 * lifetime: an invitation and a password reset differ in how long a person reasonably needs to act
 * on them, and encoding that here means no use case can accidentally mint a 72-hour reset link.
 *
 * <p>The {@code name()} of each constant is also its {@code user_credentials.credential_type} value,
 * so the enum and the schema cannot drift.
 */
public enum TokenPurpose {

  /**
   * Activates a brand-new administrative account: the recipient sets their first password and the
   * account moves {@code PENDING → ACTIVE}. Long-lived because a principal may not check email daily,
   * and it is resendable.
   *
   * <p>The only link-token purpose. Password reset does <em>not</em> use a link token — it uses an
   * emailed one-time code (ADR-0012), stored as an {@code OtpCredential} under its own
   * {@code credential_type}, so it is not modelled here.
   */
  INVITE(Duration.ofHours(72));

  private final Duration lifetime;

  TokenPurpose(Duration lifetime) {
    this.lifetime = lifetime;
  }

  public Duration lifetime() {
    return lifetime;
  }

  /** Parses a stored {@code credential_type}, or throws — an unknown value is a schema defect. */
  public static TokenPurpose fromStored(String value) {
    for (TokenPurpose purpose : values()) {
      if (purpose.name().equalsIgnoreCase(value)) {
        return purpose;
      }
    }
    throw new IllegalArgumentException("unknown token purpose: " + value);
  }
}
