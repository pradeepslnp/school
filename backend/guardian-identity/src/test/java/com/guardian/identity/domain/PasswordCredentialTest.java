package com.guardian.identity.domain;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.common.BusinessRule;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class PasswordCredentialTest {

  private static final UserId USER = UserId.of(UUID.randomUUID());
  private static final Instant NOW = Instant.parse("2026-08-14T06:00:00Z");

  private static PasswordCredential issued() {
    return PasswordCredential.issue(USER, "argon2-hash");
  }

  @Test
  @DisplayName("a fresh credential is acceptable")
  void freshCredentialIsAcceptable() {
    assertThat(issued().verdictAt(NOW)).isEqualTo(PasswordCredential.Verdict.ACCEPTABLE);
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("the account locks on the configured attempt, not before")
  void locksAfterMaxAttempts() {
    PasswordCredential credential = issued();

    for (int attempt = 1; attempt < PasswordCredential.MAX_ATTEMPTS; attempt++) {
      credential = credential.recordFailedAttempt(NOW);
      assertThat(credential.isLockedAt(NOW))
          .as("still open after %d of %d attempts", attempt, PasswordCredential.MAX_ATTEMPTS)
          .isFalse();
    }

    credential = credential.recordFailedAttempt(NOW);

    assertThat(credential.isLockedAt(NOW)).isTrue();
    assertThat(credential.verdictAt(NOW)).isEqualTo(PasswordCredential.Verdict.LOCKED);
    assertThat(credential.failedAttempts()).isEqualTo(PasswordCredential.MAX_ATTEMPTS);
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("the lock lifts when its window passes")
  void lockExpires() {
    PasswordCredential credential = issued();
    for (int attempt = 0; attempt < PasswordCredential.MAX_ATTEMPTS; attempt++) {
      credential = credential.recordFailedAttempt(NOW);
    }

    assertThat(credential.isLockedAt(NOW.plus(PasswordCredential.LOCK_DURATION))).isFalse();
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("a successful attempt clears accumulated failures, unlike a spent OTP")
  void successResetsFailureCount() {
    PasswordCredential credential = issued();
    credential = credential.recordFailedAttempt(NOW);
    credential = credential.recordFailedAttempt(NOW);
    assertThat(credential.failedAttempts()).isEqualTo(2);

    PasswordCredential recovered = credential.recordSuccessfulAttempt();

    assertThat(recovered.failedAttempts()).isZero();
    assertThat(recovered.lockedUntil()).isNull();
  }

  @Test
  @DisplayName("recording success on an already-clean credential changes nothing observable")
  void successOnCleanCredentialIsANoOp() {
    PasswordCredential credential = issued();

    PasswordCredential result = credential.recordSuccessfulAttempt();

    assertThat(result.failedAttempts()).isZero();
    assertThat(result.lockedUntil()).isNull();
  }

  @Test
  @DisplayName("the hash never appears in toString()")
  void doesNotLeakTheHash() {
    assertThat(issued().toString()).doesNotContain("argon2-hash");
  }
}
