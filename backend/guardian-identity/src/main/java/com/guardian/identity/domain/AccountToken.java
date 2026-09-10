package com.guardian.identity.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * An issued invitation or password-reset link token, and the rules governing whether it may still
 * be accepted (ADR-0012).
 *
 * <p>Shares the {@code user_credentials} table with {@link OtpCredential} and {@link
 * PasswordCredential} via {@code credential_type}, but is a distinct type for the same reason those
 * two are distinct from each other (ENGINEERING_PRINCIPLES.md §6): its states differ. A link token
 * is issued, expires, and is used exactly once — it has no attempt counter and no lock, because a
 * 256-bit secret ({@link LinkToken}) is not something an attacker guesses a digit at a time.
 *
 * <p>Immutable; every transition returns a new instance. Only the token's hash reaches this object.
 */
public final class AccountToken {

  private final UUID id;
  private final UserId userId;
  private final TokenPurpose purpose;
  private final String secretHash;
  private final Instant expiresAt;
  private final Instant consumedAt;
  private final long version;

  private AccountToken(
      UUID id,
      UserId userId,
      TokenPurpose purpose,
      String secretHash,
      Instant expiresAt,
      Instant consumedAt,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.userId = Objects.requireNonNull(userId, "userId");
    this.purpose = Objects.requireNonNull(purpose, "purpose");
    this.secretHash = Objects.requireNonNull(secretHash, "secretHash");
    this.expiresAt = Objects.requireNonNull(expiresAt, "expiresAt");
    this.consumedAt = consumedAt;
    this.version = version;
  }

  /** Issues a new token, valid for its {@link TokenPurpose#lifetime()} from {@code now}. */
  public static AccountToken issue(
      UserId userId, TokenPurpose purpose, String secretHash, Instant now) {
    return new AccountToken(
        UUID.randomUUID(), userId, purpose, secretHash, now.plus(purpose.lifetime()), null, 0);
  }

  /** Rebuilds a token from storage. */
  public static AccountToken rehydrate(
      UUID id,
      UserId userId,
      TokenPurpose purpose,
      String secretHash,
      Instant expiresAt,
      Instant consumedAt,
      long version) {
    return new AccountToken(id, userId, purpose, secretHash, expiresAt, consumedAt, version);
  }

  /** Why a token cannot be accepted, or {@link #ACCEPTABLE}. */
  public enum Verdict {
    /** The token may be checked and acted on. */
    ACCEPTABLE,

    /** Past {@code expires_at}. The client asks the person to request a fresh link. */
    EXPIRED,

    /** Already used once. Link tokens are single use. */
    ALREADY_USED
  }

  /**
   * Whether this token is in a state where it can be acted on.
   *
   * <p>Used-before-expired: a token that has been consumed is terminal whatever the clock says, and
   * reporting "already used" rather than "expired" is the more accurate thing to show the person.
   */
  public Verdict verdictAt(Instant now) {
    if (consumedAt != null) {
      return Verdict.ALREADY_USED;
    }
    if (!now.isBefore(expiresAt)) {
      return Verdict.EXPIRED;
    }
    return Verdict.ACCEPTABLE;
  }

  /** Marks the token used. Single use is enforced by this, not by deleting the row. */
  public AccountToken consume(Instant now) {
    return new AccountToken(id, userId, purpose, secretHash, expiresAt, now, version);
  }

  public UUID id() {
    return id;
  }

  public UserId userId() {
    return userId;
  }

  public TokenPurpose purpose() {
    return purpose;
  }

  /** The SHA-256 hash of the token. Compared by lookup, never rendered. */
  public String secretHash() {
    return secretHash;
  }

  public Instant expiresAt() {
    return expiresAt;
  }

  public Instant consumedAt() {
    return consumedAt;
  }

  public long version() {
    return version;
  }

  /** Deliberately excludes the hash and expiry: this string can reach logs. */
  @Override
  public String toString() {
    return "AccountToken[id="
        + id
        + ", purpose="
        + purpose
        + ", used="
        + (consumedAt != null)
        + "]";
  }
}
