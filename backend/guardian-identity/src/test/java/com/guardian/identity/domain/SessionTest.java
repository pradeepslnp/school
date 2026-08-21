package com.guardian.identity.domain;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.common.BusinessRule;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class SessionTest {

  private static final UserId USER = UserId.of(UUID.randomUUID());
  private static final Instant ISSUED = Instant.parse("2026-08-05T06:00:00Z");

  private static Session signedIn() {
    return Session.start(USER, ClientType.PARENT_APP, "hash-1", "Pixel 8", ISSUED);
  }

  @Test
  @DisplayName("a live session may be refreshed")
  void liveSessionIsRefreshable() {
    assertThat(signedIn().refreshVerdictAt(ISSUED.plusSeconds(3600)))
        .isEqualTo(Session.RefreshVerdict.ACCEPTABLE);
  }

  @Test
  @BusinessRule("BR-IAM-009")
  @DisplayName("presenting a consumed token is reported as reuse")
  void consumedTokenIsReuse() {
    Session rotated = signedIn().consume(ISSUED.plusSeconds(60));

    assertThat(rotated.refreshVerdictAt(ISSUED.plusSeconds(120)))
        .isEqualTo(Session.RefreshVerdict.REUSE_DETECTED);
  }

  @Test
  @BusinessRule("BR-IAM-009")
  @DisplayName("reuse outranks revocation and expiry, so theft is never reported as staleness")
  void reuseIsReportedAheadOfEverythingElse() {
    Session consumedThenRevoked =
        signedIn().consume(ISSUED.plusSeconds(60)).revoke("LOGOUT", ISSUED.plusSeconds(90));

    // A stolen token presented after the family was already revoked, or long after it expired,
    // is still evidence that somebody captured it. Answering EXPIRED here would discard the one
    // signal that says an attacker holds credentials — and nothing else would ever notice.
    assertThat(consumedThenRevoked.refreshVerdictAt(ISSUED.plusSeconds(120)))
        .isEqualTo(Session.RefreshVerdict.REUSE_DETECTED);
    assertThat(
            consumedThenRevoked.refreshVerdictAt(
                ISSUED.plus(ClientType.PARENT_APP.refreshLifetime()).plusSeconds(1)))
        .isEqualTo(Session.RefreshVerdict.REUSE_DETECTED);
  }

  @Test
  @BusinessRule("BR-IAM-007")
  @DisplayName("a revoked session cannot be refreshed")
  void revokedSessionIsRefused() {
    Session revoked = signedIn().revoke("LOGOUT", ISSUED.plusSeconds(60));

    assertThat(revoked.refreshVerdictAt(ISSUED.plusSeconds(120)))
        .isEqualTo(Session.RefreshVerdict.REVOKED);
  }

  @Test
  @DisplayName("an expired session cannot be refreshed")
  void expiredSessionIsRefused() {
    Session session = signedIn();

    assertThat(
            session.refreshVerdictAt(
                ISSUED.plus(ClientType.PARENT_APP.refreshLifetime()).plusSeconds(1)))
        .isEqualTo(Session.RefreshVerdict.EXPIRED);
  }

  @Test
  @BusinessRule("BR-IAM-009")
  @DisplayName("rotation keeps the family and links back to its predecessor")
  void rotationPreservesLineage() {
    Session original = signedIn();
    Session successor = original.rotateTo("hash-2", ISSUED.plusSeconds(60));

    // Without a shared family id, a token stolen before a rotation is indistinguishable from an
    // unknown one, and there is nothing to revoke when it reappears.
    assertThat(successor.familyId()).isEqualTo(original.familyId());
    assertThat(successor.previousSessionId()).isEqualTo(original.id());
    assertThat(successor.id()).isNotEqualTo(original.id());
    assertThat(successor.consumedAt()).isNull();
  }

  @Test
  @DisplayName("a guardian's session outlives a driver's")
  void refreshLifetimeVariesByClient() {
    // Losing a session mid-emergency is itself a safety problem for a parent; a driver's
    // handset is shared and changes hands between shifts.
    assertThat(ClientType.PARENT_APP.refreshLifetime())
        .isGreaterThan(ClientType.DRIVER_APP.refreshLifetime());
  }

  @Test
  @DisplayName("the refresh token hash never appears in toString()")
  void doesNotLeakTheHash() {
    assertThat(signedIn().toString()).doesNotContain("hash-1");
  }
}
