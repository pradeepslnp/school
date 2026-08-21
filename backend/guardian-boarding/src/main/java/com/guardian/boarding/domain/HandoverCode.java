package com.guardian.boarding.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * A short-lived verification code a guardian shows to release their child at drop (MOD-09, screen
 * P-12).
 *
 * <p>This is the QR / numeric-PIN method BR-HAND-002 requires at least one of. The code is shown to
 * the attendant; it does not, by itself, release anyone — that verification step lives in the
 * driver/attendant app, which does not yet exist in this codebase. See {@code
 * guardian-boarding/build.gradle.kts} for the fuller scope note.
 *
 * @param code exactly six digits, matching the mockup's grouped display ("4 8 2 9 1 3").
 */
public record HandoverCode(
    UUID id,
    UUID studentId,
    UUID requestedByGuardianId,
    String code,
    Instant issuedAt,
    Instant expiresAt) {

  public HandoverCode {
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(code, "code");
    Objects.requireNonNull(issuedAt, "issuedAt");
    Objects.requireNonNull(expiresAt, "expiresAt");

    if (!code.matches("\\d{6}")) {
      throw new IllegalArgumentException("code must be exactly six digits");
    }
    if (!expiresAt.isAfter(issuedAt)) {
      throw new IllegalArgumentException("expiresAt must be after issuedAt");
    }
  }

  /** Seconds remaining until this code stops being shown as live, floored at zero. */
  public long secondsRemaining(Instant now) {
    long seconds = expiresAt.getEpochSecond() - now.getEpochSecond();
    return Math.max(0, seconds);
  }
}
