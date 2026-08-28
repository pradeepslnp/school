package com.guardian.identity.domain;

/**
 * Whether a person may hold a session.
 *
 * <p>{@code INACTIVE} and {@code LOCKED} are distinct in the database and identical to the client:
 * both refuse sign-in with {@code AUTH_CREDENTIALS_INVALID}. Telling a caller which one applies
 * confirms the number belongs to a real account.
 */
public enum UserStatus {

  /** May sign in. */
  ACTIVE,

  /** Deactivated — a staff member who left, or a guardian whose links were removed. */
  INACTIVE,

  /** Locked by repeated failed attempts (BR-IAM-011). */
  LOCKED,

  /**
   * Invited but not yet activated: an administrative account created by invitation (ADR-0012) that
   * has no password yet. Cannot sign in until the invitation is accepted, which sets the password
   * and moves the account to {@link #ACTIVE}.
   */
  PENDING;

  public boolean canAuthenticate() {
    return this == ACTIVE;
  }

  /** Parses the stored value, treating anything unrecognised as unable to authenticate. */
  public static UserStatus fromStored(String value) {
    for (UserStatus status : values()) {
      if (status.name().equalsIgnoreCase(value)) {
        return status;
      }
    }
    // Fails closed. A status this build does not know about must not be assumed signable-in.
    return INACTIVE;
  }
}
