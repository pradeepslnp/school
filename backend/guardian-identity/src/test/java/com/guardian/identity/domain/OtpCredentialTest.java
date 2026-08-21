package com.guardian.identity.domain;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.common.BusinessRule;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class OtpCredentialTest {

  private static final UserId USER = UserId.of(UUID.randomUUID());
  private static final Instant ISSUED = Instant.parse("2026-08-05T06:00:00Z");

  private static OtpCredential issued() {
    return OtpCredential.issue(USER, "argon2-hash", ISSUED);
  }

  @Test
  @DisplayName("a fresh code is acceptable within its lifetime")
  void freshCodeIsAcceptable() {
    assertThat(issued().verdictAt(ISSUED.plusSeconds(60)))
        .isEqualTo(OtpCredential.Verdict.ACCEPTABLE);
  }

  @Test
  @DisplayName("a code is dead the instant it expires, not a moment after")
  void expiresAtTheBoundary() {
    OtpCredential credential = issued();
    Instant expiry = ISSUED.plus(OtpCredential.LIFETIME);

    // Asserted at the exact boundary because an off-by-one here is invisible in ordinary use
    // and only shows up as a code that works one request longer than the contract says.
    assertThat(credential.verdictAt(expiry.minusMillis(1)))
        .isEqualTo(OtpCredential.Verdict.ACCEPTABLE);
    assertThat(credential.verdictAt(expiry)).isEqualTo(OtpCredential.Verdict.EXPIRED);
  }

  @Test
  @DisplayName("a consumed code cannot be used again")
  void singleUse() {
    OtpCredential consumed = issued().consume(ISSUED.plusSeconds(10));

    assertThat(consumed.verdictAt(ISSUED.plusSeconds(20)))
        .isEqualTo(OtpCredential.Verdict.ALREADY_USED);
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("the account locks on the configured attempt, not before")
  void locksAfterMaxAttempts() {
    OtpCredential credential = issued();

    for (int attempt = 1; attempt < OtpCredential.MAX_ATTEMPTS; attempt++) {
      credential = credential.recordFailedAttempt(ISSUED);
      assertThat(credential.isLockedAt(ISSUED))
          .as("still open after %d of %d attempts", attempt, OtpCredential.MAX_ATTEMPTS)
          .isFalse();
    }

    credential = credential.recordFailedAttempt(ISSUED);

    assertThat(credential.isLockedAt(ISSUED)).isTrue();
    assertThat(credential.failedAttempts()).isEqualTo(OtpCredential.MAX_ATTEMPTS);
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("a lock outranks every other verdict, so it cannot be used as an oracle")
  void lockTakesPrecedence() {
    OtpCredential credential = issued();
    for (int attempt = 0; attempt < OtpCredential.MAX_ATTEMPTS; attempt++) {
      credential = credential.recordFailedAttempt(ISSUED);
    }
    OtpCredential lockedAndConsumed = credential.consume(ISSUED);

    // If ALREADY_USED or EXPIRED were reported ahead of LOCKED, the response would vary with
    // the code's state while the account is locked — and a response that varies is a signal an
    // attacker can read. The lock has to answer identically to everything.
    assertThat(lockedAndConsumed.verdictAt(ISSUED.plusSeconds(1)))
        .isEqualTo(OtpCredential.Verdict.LOCKED);
    assertThat(lockedAndConsumed.verdictAt(ISSUED.plus(OtpCredential.LIFETIME).plusSeconds(1)))
        .isEqualTo(OtpCredential.Verdict.LOCKED);
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("the lock lifts when its window passes")
  void lockExpires() {
    OtpCredential credential = issued();
    for (int attempt = 0; attempt < OtpCredential.MAX_ATTEMPTS; attempt++) {
      credential = credential.recordFailedAttempt(ISSUED);
    }

    // A permanent lock would make a mistyped code at a school gate into a support ticket, and
    // the parent cannot see where their child is until it is resolved.
    assertThat(credential.isLockedAt(ISSUED.plus(OtpCredential.LOCK_DURATION))).isFalse();
  }

  @Test
  @DisplayName("the code's hash never appears in toString()")
  void doesNotLeakTheHash() {
    assertThat(issued().toString()).doesNotContain("argon2-hash");
  }
}
