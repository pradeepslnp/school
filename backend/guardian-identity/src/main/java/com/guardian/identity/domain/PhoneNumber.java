package com.guardian.identity.domain;

import java.util.Objects;

/**
 * A guardian's mobile number, in the one form the platform stores.
 *
 * <p>Normalisation is the entire point of this type. The same parent will type {@code +91 80506
 * 02046}, {@code 08050602046}, and {@code 8050602046} across three sign-ins, and all three must
 * resolve to one row in {@code users}. Doing that comparison in SQL — or, worse, in each caller —
 * is how a person ends up with two accounts and sees half their children.
 *
 * <p><strong>No format validation lives here.</strong> Valid length and prefix vary by country and
 * belong to the region profile (ADR-0007); a pattern hardcoded here would reject legitimate numbers
 * in the next country the platform sells into. What this type guarantees is a canonical
 * representation, not a valid one.
 */
public record PhoneNumber(String value) {

  /**
   * Shortest number this will accept. Not a validity rule — a floor below which the input cannot be
   * a phone number at all and is more likely a typo or a probe.
   */
  private static final int MINIMUM_DIGITS = 8;

  /** E.164 permits at most 15 digits. Anything longer is not a phone number. */
  private static final int MAXIMUM_DIGITS = 15;

  public PhoneNumber {
    Objects.requireNonNull(value, "value");
  }

  /**
   * Normalises raw user input into the stored form: digits only, no leading zeros or plus.
   *
   * <p>Returns a {@code PhoneNumber} for anything plausible and throws for anything that cannot be
   * one. Callers translate the exception into {@code AUTH_CREDENTIALS_INVALID} — never into a
   * message that distinguishes "malformed" from "not registered", which would enumerate accounts.
   *
   * @throws IllegalArgumentException if the input holds too few or too many digits
   */
  public static PhoneNumber of(String raw) {
    Objects.requireNonNull(raw, "raw");

    String digits = raw.replaceAll("\\D", "");

    // A national trunk prefix ("08050602046") and an international one ("+91…") are the same
    // subscriber. Stripping leading zeros makes them converge without needing to know the
    // country, which this type deliberately does not.
    digits = digits.replaceFirst("^0+", "");

    if (digits.length() < MINIMUM_DIGITS || digits.length() > MAXIMUM_DIGITS) {
      throw new IllegalArgumentException("phone number must hold 8 to 15 digits");
    }
    return new PhoneNumber(digits);
  }

  /**
   * A form safe to write to a log or an audit record.
   *
   * <p>A full mobile number identifies a family at a named school, so it is never logged whole. The
   * last four digits are enough for support to confirm they are looking at the right person and not
   * enough to contact them.
   */
  public String masked() {
    int visible = 4;
    if (value.length() <= visible) {
      return "*".repeat(value.length());
    }
    return "*".repeat(value.length() - visible) + value.substring(value.length() - visible);
  }

  /** Never the raw number — {@code toString} ends up in logs by accident, so it is masked. */
  @Override
  public String toString() {
    return masked();
  }
}
