package com.guardian.identity.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/** JPA mapping for {@code sessions}. */
@Entity
@Table(name = "sessions")
public class SessionEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "user_id", nullable = false, updatable = false)
  private UUID userId;

  @Column(name = "refresh_token_hash", nullable = false, updatable = false)
  private String refreshTokenHash;

  @Column(name = "family_id", nullable = false, updatable = false)
  private UUID familyId;

  @Column(name = "previous_session_id", updatable = false)
  private UUID previousSessionId;

  @Column(name = "client_type", nullable = false, length = 24, updatable = false)
  private String clientType;

  @Column(name = "device_identifier")
  private String deviceIdentifier;

  @Column(name = "issued_at", nullable = false, updatable = false)
  private Instant issuedAt;

  @Column(name = "expires_at", nullable = false, updatable = false)
  private Instant expiresAt;

  @Column(name = "consumed_at")
  private Instant consumedAt;

  @Column(name = "is_revoked", nullable = false)
  private boolean revoked;

  @Column(name = "revoked_reason", length = 64)
  private String revokedReason;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected SessionEntity() {
    // required by JPA
  }

  SessionEntity(
      UUID id,
      UUID tenantId,
      UUID userId,
      String refreshTokenHash,
      UUID familyId,
      UUID previousSessionId,
      String clientType,
      String deviceIdentifier,
      Instant issuedAt,
      Instant expiresAt,
      Instant consumedAt,
      boolean revoked,
      String revokedReason) {
    this.id = id;
    this.tenantId = tenantId;
    this.userId = userId;
    this.refreshTokenHash = refreshTokenHash;
    this.familyId = familyId;
    this.previousSessionId = previousSessionId;
    this.clientType = clientType;
    this.deviceIdentifier = deviceIdentifier;
    this.issuedAt = issuedAt;
    this.expiresAt = expiresAt;
    this.consumedAt = consumedAt;
    this.revoked = revoked;
    this.revokedReason = revokedReason;
  }

  /**
   * A session's lifecycle only ever moves forward: consumed, then revoked. Nothing else about an
   * issued session may change, which is why the other columns are not updatable.
   */
  void applyLifecycle(Instant consumedAt, boolean revoked, String revokedReason) {
    this.consumedAt = consumedAt;
    this.revoked = revoked;
    this.revokedReason = revokedReason;
  }

  UUID getId() {
    return id;
  }

  UUID getUserId() {
    return userId;
  }

  String getRefreshTokenHash() {
    return refreshTokenHash;
  }

  UUID getFamilyId() {
    return familyId;
  }

  UUID getPreviousSessionId() {
    return previousSessionId;
  }

  String getClientType() {
    return clientType;
  }

  String getDeviceIdentifier() {
    return deviceIdentifier;
  }

  Instant getIssuedAt() {
    return issuedAt;
  }

  Instant getExpiresAt() {
    return expiresAt;
  }

  Instant getConsumedAt() {
    return consumedAt;
  }

  boolean isRevoked() {
    return revoked;
  }

  String getRevokedReason() {
    return revokedReason;
  }

  long getVersion() {
    return version;
  }

  /** Excludes the token hash. */
  @Override
  public String toString() {
    return "SessionEntity[id=" + id + ", family=" + familyId + "]";
  }
}
