package com.guardian.student.domain;

/**
 * Where a student stands in the school's roll (BR-STU-004, BR-STU-005).
 *
 * <p>Only {@link #ACTIVE} students may be assigned to routes or appear on a manifest. The other
 * three are terminal for transport purposes but keep the record readable, because safety records
 * reference it long after the child has left.
 */
public enum EnrolmentStatus {

  /** On the roll and eligible for transport, subject to {@code transportEligible}. */
  ACTIVE,

  /** Temporarily off the roll — a long absence, a suspended enrolment. */
  INACTIVE,

  /** Left the school. */
  WITHDRAWN,

  /** Moved to another school on the platform (STU-005, not yet built). */
  TRANSFERRED;

  /** BR-STU-004: assignment and manifests admit active students only. */
  public boolean allowsTransport() {
    return this == ACTIVE;
  }

  public static EnrolmentStatus fromStored(String stored) {
    return valueOf(stored);
  }
}
