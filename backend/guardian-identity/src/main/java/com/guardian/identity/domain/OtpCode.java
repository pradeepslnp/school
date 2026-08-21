package com.guardian.identity.domain;

import java.security.SecureRandom;
import java.util.Objects;

/**
 * A one-time code sent to a guardian by SMS.
 *
 * <p>Six digits, generated from {@link SecureRandom}. {@code java.util.Random} would be seeded from
 * the clock and its output predictable from a couple of observed codes — an attacker who can
 * request an OTP for their own number could then predict one issued to somebody else's.
 *
 * <p>Six digits is only ~20 bits, which is why the code alone is never the control. Three things
 * hold together: a short lifetime, single use, and a per-identifier attempt limit (BR-IAM-011).
 * Remove any one and the remaining space is searchable.
 */
public record OtpCode(String value) {

  public static final int LENGTH = 6;

  private static final SecureRandom RANDOM = new SecureRandom();

  public OtpCode {
    Objects.requireNonNull(value, "value");
    if (value.length() != LENGTH || !value.chars().allMatch(Character::isDigit)) {
      throw new IllegalArgumentException("otp must be " + LENGTH + " digits");
    }
  }

  /** Generates a fresh code. */
  public static OtpCode generate() {
    // Formatted with leading zeros rather than drawn from 100000..999999: excluding codes
    // that begin with a zero would remove a tenth of an already small space.
    return new OtpCode(("%0" + LENGTH + "d").formatted(RANDOM.nextInt(1_000_000)));
  }

  /**
   * Parses a code typed by a guardian, or throws.
   *
   * <p>Callers turn the exception into the same failure a wrong code produces. A distinct "that is
   * not six digits" response would confirm the code format to somebody probing the endpoint.
   */
  public static OtpCode of(String raw) {
    Objects.requireNonNull(raw, "raw");
    return new OtpCode(raw.trim());
  }

  /** Never renders the code — an OTP in a log is a credential in a log. */
  @Override
  public String toString() {
    return "*".repeat(LENGTH);
  }
}
