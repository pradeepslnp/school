package com.guardian.identity.domain;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * A staff member's password, and the rules governing whether a submitted one may still be checked
 * (feature IAM-001).
 *
 * <p>Deliberately not modelled as a variant of {@link OtpCredential}, even though the two share a
 * table and much of their attempt-lockout shape. A password is not issued and does not expire or
 * get consumed — it is checked repeatedly across many sign-ins — so {@link OtpCredential.Verdict}
 * has states (EXPIRED, ALREADY_USED) that make no sense here, and forcing one type to cover both
 * would mean every caller of either handles states that cannot occur for it
 * (ENGINEERING_PRINCIPLES.md §6: rules that look alike but change for different reasons are not
 * duplication).
 *
 * <p>Immutable, like every other domain object here. Every transition returns a new instance.
 *
 * <p>The password itself is never held. Only its Argon2id hash reaches this object.
 */
public final class PasswordCredential {

  /**
   * Wrong passwords tolerated before the account is locked (BR-IAM-011).
   *
   * <p>Same figure as {@link OtpCredential#MAX_ATTEMPTS}, and stated independently rather than
   * shared: a password is a secret its owner chose and can be much higher entropy than a six-digit
   * code, so this number is free to diverge from the OTP figure later without dragging the guardian
   * sign-in path along with it.
   */
  public static final int MAX_ATTEMPTS = 5;

  /** How long a lock lasts once the attempt limit is reached. */
  public static final Duration LOCK_DURATION = Duration.ofMinutes(15);

  private final UUID id;
  private final UserId userId;
  private final String secretHash;
  private final int failedAttempts;
  private final Instant lockedUntil;
  private final long version;

  private PasswordCredential(
      UUID id,
      UserId userId,
      String secretHash,
      int failedAttempts,
      Instant lockedUntil,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.userId = Objects.requireNonNull(userId, "userId");
    this.secretHash = Objects.requireNonNull(secretHash, "secretHash");
    this.failedAttempts = failedAttempts;
    this.lockedUntil = lockedUntil;
    this.version = version;
  }

  /** Sets a password for the first time. Provisioning staff accounts is a separate feature. */
  public static PasswordCredential issue(UserId userId, String secretHash) {
    return new PasswordCredential(UUID.randomUUID(), userId, secretHash, 0, null, 0);
  }

  /**
   * Replaces the secret on an existing credential (a password reset, ADR-0012), keeping the same
   * row {@code id} so the reset updates the one PASSWORD row rather than inserting a second and
   * tripping {@code uq_user_credentials_password}. Any accumulated failures and lock are cleared —
   * a freshly-set password starts clean.
   */
  public PasswordCredential reissue(String newSecretHash) {
    return new PasswordCredential(id, userId, newSecretHash, 0, null, version);
  }

  /** Rebuilds a credential from storage. */
  public static PasswordCredential rehydrate(
      UUID id,
      UserId userId,
      String secretHash,
      int failedAttempts,
      Instant lockedUntil,
      long version) {
    return new PasswordCredential(id, userId, secretHash, failedAttempts, lockedUntil, version);
  }

  /** Whether a submitted password may be checked against {@link #secretHash()} at all. */
  public enum Verdict {
    /** The password may be compared. */
    ACCEPTABLE,

    /** Too many wrong attempts; the account is locked for now (BR-IAM-011). */
    LOCKED
  }

  /**
   * Lock first, and lock alone — unlike {@link OtpCredential} there is no expiry or single-use
   * state to rank it against. A locked account must answer identically whatever password is
   * submitted, otherwise the lock becomes an oracle that still leaks whether a guess was close.
   */
  public Verdict verdictAt(Instant now) {
    return isLockedAt(now) ? Verdict.LOCKED : Verdict.ACCEPTABLE;
  }

  public boolean isLockedAt(Instant now) {
    return lockedUntil != null && now.isBefore(lockedUntil);
  }

  /**
   * Records a wrong password, locking the account once {@link #MAX_ATTEMPTS} is reached.
   *
   * <p>The increment and the lock are applied together in one returned instance, for the same
   * reason as {@link OtpCredential#recordFailedAttempt}: two separate writes would leave a window
   * where the counter says five and no lock is yet in force, which is exactly the window a
   * concurrent attacker exercises.
   */
  public PasswordCredential recordFailedAttempt(Instant now) {
    int attempts = failedAttempts + 1;
    Instant lock = attempts >= MAX_ATTEMPTS ? now.plus(LOCK_DURATION) : lockedUntil;
    return new PasswordCredential(id, userId, secretHash, attempts, lock, version);
  }

  /**
   * Records a correct password, clearing any accumulated failures.
   *
   * <p>Unlike an OTP row, which is single-use and simply stops mattering once consumed, a password
   * row is checked again at the next sign-in. Leaving the failure count from a previous,
   * eventually-successful attempt in place would let a handful of mistyped passwords across
   * separate days quietly accumulate toward a lock nobody is actively trying to trigger.
   */
  public PasswordCredential recordSuccessfulAttempt() {
    if (failedAttempts == 0 && lockedUntil == null) {
      return this;
    }
    return new PasswordCredential(id, userId, secretHash, 0, null, version);
  }

  public UUID id() {
    return id;
  }

  public UserId userId() {
    return userId;
  }

  /**
   * The Argon2id hash. Compared by the hashing port, never by this class — constant-time comparison
   * is a property of the algorithm's implementation.
   */
  public String secretHash() {
    return secretHash;
  }

  public int failedAttempts() {
    return failedAttempts;
  }

  public Instant lockedUntil() {
    return lockedUntil;
  }

  public long version() {
    return version;
  }

  /** Deliberately excludes the hash: this string ends up in logs. */
  @Override
  public String toString() {
    return "PasswordCredential[id=" + id + ", attempts=" + failedAttempts + "]";
  }
}
