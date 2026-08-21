package com.guardian.identity.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code user_credentials}.
 *
 * <p>{@code secretHash} is the only credential material in the codebase that is loaded into memory
 * at all. It is never copied into a DTO, never logged, and deliberately absent from {@link
 * #toString()} — an entity whose default {@code toString} prints every field is one careless debug
 * statement away from putting an Argon2 hash in a log aggregator.
 */
@Entity
@Table(name = "user_credentials")
public class UserCredentialEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "user_id", nullable = false, updatable = false)
  private UUID userId;

  @Column(name = "credential_type", nullable = false, length = 24, updatable = false)
  private String credentialType;

  @Column(name = "secret_hash", nullable = false)
  private String secretHash;

  @Column(name = "expires_at")
  private Instant expiresAt;

  @Column(name = "consumed_at")
  private Instant consumedAt;

  @Column(name = "failed_attempts", nullable = false)
  private int failedAttempts;

  @Column(name = "locked_until")
  private Instant lockedUntil;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected UserCredentialEntity() {
    // required by JPA
  }

  UserCredentialEntity(
      UUID id,
      UUID tenantId,
      UUID userId,
      String credentialType,
      String secretHash,
      Instant expiresAt,
      Instant consumedAt,
      int failedAttempts,
      Instant lockedUntil) {
    this.id = id;
    this.tenantId = tenantId;
    this.userId = userId;
    this.credentialType = credentialType;
    this.secretHash = secretHash;
    this.expiresAt = expiresAt;
    this.consumedAt = consumedAt;
    this.failedAttempts = failedAttempts;
    this.lockedUntil = lockedUntil;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  /** The three columns an attempt can change. The hash and expiry are fixed at issue. */
  void applyAttemptState(Instant consumedAt, int failedAttempts, Instant lockedUntil) {
    this.consumedAt = consumedAt;
    this.failedAttempts = failedAttempts;
    this.lockedUntil = lockedUntil;
    this.updatedAt = Instant.now();
  }

  UUID getId() {
    return id;
  }

  UUID getUserId() {
    return userId;
  }

  String getSecretHash() {
    return secretHash;
  }

  Instant getExpiresAt() {
    return expiresAt;
  }

  Instant getConsumedAt() {
    return consumedAt;
  }

  int getFailedAttempts() {
    return failedAttempts;
  }

  Instant getLockedUntil() {
    return lockedUntil;
  }

  long getVersion() {
    return version;
  }

  /** Excludes the hash. */
  @Override
  public String toString() {
    return "UserCredentialEntity[id=" + id + ", type=" + credentialType + "]";
  }
}
