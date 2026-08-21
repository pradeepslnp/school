package com.guardian.guardian.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * An adult authorised to collect a child who is not a guardian (BR-GRD-005).
 *
 * <p><strong>The validity window is part of the type, not a field someone may omit.</strong> Both
 * bounds are required and the constructor refuses an inverted or empty one. A permanent nomination
 * made once and forgotten is a standing authorisation nobody reviews — the commonest way an
 * authorisation list stops reflecting reality — so extending one is an explicit act.
 *
 * <p>{@code relationshipNote} ("Uncle") is descriptive only and confers nothing, exactly as {@code
 * relationship_type} does on a guardian link. Authority comes from being on this list and inside
 * the window, never from what the relationship is called.
 */
public record PickupPerson(
    UUID id,
    UUID studentId,
    UUID nominatedByGuardianId,
    String fullName,
    String phone,
    String relationshipNote,
    Instant validFrom,
    Instant validUntil,
    boolean active) {

  public PickupPerson {
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(fullName, "fullName");
    Objects.requireNonNull(phone, "phone");
    Objects.requireNonNull(validFrom, "validFrom");
    Objects.requireNonNull(validUntil, "validUntil");

    if (!validUntil.isAfter(validFrom)) {
      throw new IllegalArgumentException("validUntil must be after validFrom");
    }
  }

  /**
   * Whether this nomination authorises a collection happening at {@code at}.
   *
   * <p>Revocation is immediate (BR-GRD-007), so an inactive nomination never authorises anything
   * regardless of its window.
   */
  public boolean authorisesAt(Instant at) {
    return active && !at.isBefore(validFrom) && !at.isAfter(validUntil);
  }
}
