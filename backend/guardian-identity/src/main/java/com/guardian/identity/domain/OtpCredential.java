package com.guardian.identity.domain;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * A one-time code that has been issued to a guardian, and the rules governing whether it may still
 * be accepted.
 *
 * <p>Every decision about an OTP lives here rather than in the use case. That matters because the
 * decisions are not independent: a code can be simultaneously expired and consumed, an account can
 * be locked while a fresh code is live, and the order in which those are evaluated changes what an
 * attacker learns. Spread across a service method, the ordering is accidental. Here it is one
 * method that can be read and tested in isolation.
 *
 * <p>Immutable. Every transition returns a new instance, so a partially-applied change cannot exist
 * — there is no window in which attempts have been incremented but the lock has not been applied.
 *
 * <p>The code itself is never held. Only its Argon2id hash reaches this object, so a heap dump
 * taken during verification does not contain a usable credential.
 */
public final class OtpCredential {

  /**
   * How long a code stays valid.
   *
   * <p>Five minutes is long enough for an SMS to arrive on a slow network at the school gate, and
   * short enough that a code read off a lock screen hours later is worthless. It is stated in the
   * API contract, so the client can show a countdown.
   */
  public static final Duration LIFETIME = Duration.ofMinutes(5);

  /**
   * Wrong codes tolerated before the account is locked (BR-IAM-011).
   *
   * <p>Five, against a six-digit code, leaves a one-in-two-hundred-thousand chance per lockout
   * window. Higher and the space becomes searchable; much lower and a parent fat-fingering a digit
   * twice at a school gate is locked out of the app that shows them where their child is.
   */
  public static final int MAX_ATTEMPTS = 5;

  /** How long a lock lasts once the attempt limit is reached. */
  public static final Duration LOCK_DURATION = Duration.ofMinutes(15);

  private final UUID id;
  private final UserId userId;
  private final String secretHash;
  private final Instant expiresAt;
  private final Instant consumedAt;
  private final int failedAttempts;
  private final Instant lockedUntil;
  private final long version;

  private OtpCredential(
      UUID id,
      UserId userId,
      String secretHash,
      Instant expiresAt,
      Instant consumedAt,
      int failedAttempts,
      Instant lockedUntil,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.userId = Objects.requireNonNull(userId, "userId");
    this.secretHash = Objects.requireNonNull(secretHash, "secretHash");
    this.expiresAt = Objects.requireNonNull(expiresAt, "expiresAt");
    this.consumedAt = consumedAt;
    this.failedAttempts = failedAttempts;
    this.lockedUntil = lockedUntil;
    this.version = version;
  }

  /** Issues a new code for {@code userId}, valid for {@link #LIFETIME} from {@code now}. */
  public static OtpCredential issue(UserId userId, String secretHash, Instant now) {
    return new OtpCredential(
        UUID.randomUUID(), userId, secretHash, now.plus(LIFETIME), null, 0, null, 0);
  }

  /** Rebuilds a credential from storage. */
  public static OtpCredential rehydrate(
      UUID id,
      UserId userId,
      String secretHash,
      Instant expiresAt,
      Instant consumedAt,
      int failedAttempts,
      Instant lockedUntil,
      long version) {
    return new OtpCredential(
        id, userId, secretHash, expiresAt, consumedAt, failedAttempts, lockedUntil, version);
  }

  /** Why a code cannot be accepted, or {@link #ACCEPTABLE}. */
  public enum Verdict {
    /** The code may be checked against the stored hash. */
    ACCEPTABLE,

    /** Too many wrong attempts; the account is locked for now (BR-IAM-011). */
    LOCKED,

    /** Past {@code expires_at}. Retyping cannot help — the client asks for a new code. */
    EXPIRED,

    /** Already accepted once. OTPs are single use. */
    ALREADY_USED
  }

  /**
   * Whether this credential is in a state where a submitted code could be checked at all.
   *
   * <p>Ordering is deliberate and is the reason this is one method:
   *
   * <ol>
   *   <li><strong>Lock first.</strong> A locked account must answer identically whatever code is
   *       submitted, otherwise the lock becomes an oracle that still leaks whether a guess was
   *       right.
   *   <li><strong>Then already-used, then expired.</strong> Both are terminal and neither reveals
   *       anything an attacker did not already know — they requested the code's timing themselves.
   *       Reporting them distinctly is what lets the app clear the field and offer a new code
   *       instead of leaving a parent retyping digits that can never work.
   * </ol>
   */
  public Verdict verdictAt(Instant now) {
    if (isLockedAt(now)) {
      return Verdict.LOCKED;
    }
    if (consumedAt != null) {
      return Verdict.ALREADY_USED;
    }
    if (!now.isBefore(expiresAt)) {
      return Verdict.EXPIRED;
    }
    return Verdict.ACCEPTABLE;
  }

  public boolean isLockedAt(Instant now) {
    return lockedUntil != null && now.isBefore(lockedUntil);
  }

  /**
   * Marks the code used. Single use is enforced by this, not by deleting the row — a consumed code
   * stays visible to the audit trail.
   */
  public OtpCredential consume(Instant now) {
    return new OtpCredential(
        id, userId, secretHash, expiresAt, now, failedAttempts, lockedUntil, version);
  }

  /**
   * Records a wrong code, locking the account once {@link #MAX_ATTEMPTS} is reached.
   *
   * <p>The increment and the lock are applied together in one returned instance. Two separate
   * operations would leave a window in which the counter says five and no lock is in force — and
   * that window is exactly what a concurrent attacker exercises.
   */
  public OtpCredential recordFailedAttempt(Instant now) {
    int attempts = failedAttempts + 1;
    Instant lock = attempts >= MAX_ATTEMPTS ? now.plus(LOCK_DURATION) : lockedUntil;
    return new OtpCredential(
        id, userId, secretHash, expiresAt, consumedAt, attempts, lock, version);
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

  public Instant expiresAt() {
    return expiresAt;
  }

  public Instant consumedAt() {
    return consumedAt;
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

  /** Deliberately excludes the hash and the expiry: this string ends up in logs. */
  @Override
  public String toString() {
    return "OtpCredential[id=" + id + ", attempts=" + failedAttempts + "]";
  }
}
