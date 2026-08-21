package com.guardian.identity.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * An issued session, and the rules that decide whether its refresh token may still be exchanged.
 *
 * <p>The refresh token is opaque and single use. Rotation produces a new session in the same
 * <em>family</em>, linked back through {@code previousSessionId}, and consumes this one.
 *
 * <p><strong>{@code familyId} is what makes theft detectable.</strong> Presenting a token that has
 * already been consumed means two parties hold it: the legitimate client, which rotated, and
 * somebody who captured the earlier value. Which of the two is presenting it now cannot be
 * determined — so the entire family is revoked (BR-IAM-009). The legitimate user is signed out too.
 * That is the correct trade: a captured refresh token in a system holding children's live locations
 * is not something to resolve gently.
 *
 * <p>Immutable, like every other domain object here. State transitions return new instances.
 */
public final class Session {

  private final SessionId id;
  private final UserId userId;
  private final String refreshTokenHash;
  private final UUID familyId;
  private final SessionId previousSessionId;
  private final ClientType clientType;
  private final String deviceIdentifier;
  private final Instant issuedAt;
  private final Instant expiresAt;
  private final Instant consumedAt;
  private final boolean revoked;
  private final String revokedReason;
  private final long version;

  private Session(
      SessionId id,
      UserId userId,
      String refreshTokenHash,
      UUID familyId,
      SessionId previousSessionId,
      ClientType clientType,
      String deviceIdentifier,
      Instant issuedAt,
      Instant expiresAt,
      Instant consumedAt,
      boolean revoked,
      String revokedReason,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.userId = Objects.requireNonNull(userId, "userId");
    this.refreshTokenHash = Objects.requireNonNull(refreshTokenHash, "refreshTokenHash");
    this.familyId = Objects.requireNonNull(familyId, "familyId");
    this.previousSessionId = previousSessionId;
    this.clientType = Objects.requireNonNull(clientType, "clientType");
    this.deviceIdentifier = deviceIdentifier;
    this.issuedAt = Objects.requireNonNull(issuedAt, "issuedAt");
    this.expiresAt = Objects.requireNonNull(expiresAt, "expiresAt");
    this.consumedAt = consumedAt;
    this.revoked = revoked;
    this.revokedReason = revokedReason;
    this.version = version;
  }

  /** Starts a new session family — a fresh sign-in, not a rotation. */
  public static Session start(
      UserId userId,
      ClientType clientType,
      String refreshTokenHash,
      String deviceIdentifier,
      Instant now) {
    return new Session(
        SessionId.of(UUID.randomUUID()),
        userId,
        refreshTokenHash,
        UUID.randomUUID(),
        null,
        clientType,
        deviceIdentifier,
        now,
        now.plus(clientType.refreshLifetime()),
        null,
        false,
        null,
        0);
  }

  public static Session rehydrate(
      SessionId id,
      UserId userId,
      String refreshTokenHash,
      UUID familyId,
      SessionId previousSessionId,
      ClientType clientType,
      String deviceIdentifier,
      Instant issuedAt,
      Instant expiresAt,
      Instant consumedAt,
      boolean revoked,
      String revokedReason,
      long version) {
    return new Session(
        id,
        userId,
        refreshTokenHash,
        familyId,
        previousSessionId,
        clientType,
        deviceIdentifier,
        issuedAt,
        expiresAt,
        consumedAt,
        revoked,
        revokedReason,
        version);
  }

  /** Whether a presented refresh token may be exchanged. */
  public enum RefreshVerdict {
    /** May be rotated. */
    ACCEPTABLE,

    /**
     * Already consumed. The token was captured — the family is revoked and an alert raised
     * (BR-IAM-009).
     */
    REUSE_DETECTED,

    /** Revoked by logout, by a reuse elsewhere in the family, or by staff deactivation. */
    REVOKED,

    /** Past its lifetime. Ordinary; the user signs in again. */
    EXPIRED
  }

  /**
   * Ordering matters here as much as it does for OTP verification.
   *
   * <p>Reuse is checked <strong>before</strong> revocation and expiry. A stolen token presented
   * after the family was already revoked, or after it expired, is still evidence of theft, and
   * answering "expired" would discard the one signal that says an attacker holds credentials.
   */
  public RefreshVerdict refreshVerdictAt(Instant now) {
    if (consumedAt != null) {
      return RefreshVerdict.REUSE_DETECTED;
    }
    if (revoked) {
      return RefreshVerdict.REVOKED;
    }
    if (!now.isBefore(expiresAt)) {
      return RefreshVerdict.EXPIRED;
    }
    return RefreshVerdict.ACCEPTABLE;
  }

  /** Marks this session's refresh token spent. */
  public Session consume(Instant now) {
    return copyWith(now, revoked, revokedReason);
  }

  /**
   * Revokes the session immediately.
   *
   * <p>The refresh token stops working at once. The access token remains verifiable until it
   * expires or the denylist propagates, which is the ≤15-minute window ADR-0006 accepts and
   * BR-IAM-007 states.
   */
  public Session revoke(String reason, Instant now) {
    // consumedAt is deliberately left alone. The two columns mean different things — consumed
    // means "this refresh token was spent by a rotation", revoked means "this session is over"
    // — and collapsing them makes every ordinary logout indistinguishable from theft. The
    // revoked token would then come back as REUSE_DETECTED, revoking the family and raising a
    // security alert for a parent who simply signed out.
    return new Session(
        id,
        userId,
        refreshTokenHash,
        familyId,
        previousSessionId,
        clientType,
        deviceIdentifier,
        issuedAt,
        expiresAt,
        consumedAt,
        true,
        reason,
        version);
  }

  /**
   * Rotates into a successor sharing this session's family. Call {@link #consume} on this one in
   * the same transaction — a rotation that produces a successor without spending its predecessor
   * leaves two live tokens.
   */
  public Session rotateTo(String newRefreshTokenHash, Instant now) {
    return new Session(
        SessionId.of(UUID.randomUUID()),
        userId,
        newRefreshTokenHash,
        familyId,
        id,
        clientType,
        deviceIdentifier,
        now,
        now.plus(clientType.refreshLifetime()),
        null,
        false,
        null,
        0);
  }

  private Session copyWith(Instant newConsumedAt, boolean newRevoked, String newRevokedReason) {
    return new Session(
        id,
        userId,
        refreshTokenHash,
        familyId,
        previousSessionId,
        clientType,
        deviceIdentifier,
        issuedAt,
        expiresAt,
        newConsumedAt,
        newRevoked,
        newRevokedReason,
        version);
  }

  public SessionId id() {
    return id;
  }

  public UserId userId() {
    return userId;
  }

  public String refreshTokenHash() {
    return refreshTokenHash;
  }

  public UUID familyId() {
    return familyId;
  }

  public SessionId previousSessionId() {
    return previousSessionId;
  }

  public ClientType clientType() {
    return clientType;
  }

  public String deviceIdentifier() {
    return deviceIdentifier;
  }

  public Instant issuedAt() {
    return issuedAt;
  }

  public Instant expiresAt() {
    return expiresAt;
  }

  public Instant consumedAt() {
    return consumedAt;
  }

  public boolean isRevoked() {
    return revoked;
  }

  public String revokedReason() {
    return revokedReason;
  }

  public long version() {
    return version;
  }

  /** Excludes the token hash. */
  @Override
  public String toString() {
    return "Session[id=" + id + ", family=" + familyId + ", client=" + clientType + "]";
  }
}
