package com.guardian.absence.domain;

import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * A guardian's declaration that a child is not travelling (MOD-14, ABS-001).
 *
 * <p>Its whole purpose is downstream: an active declaration removes the child from the manifest
 * materialised at trip start (BR-ABS-002), which is what stops trip-close reconciliation raising a
 * false alarm about a child who was never coming. An absence is therefore not a note on a profile —
 * it is an input to a safety calculation.
 *
 * @param direction null means <strong>both</strong> journeys. Modelled as a nullable field rather
 *     than a third enum value because that is the wire contract
 *     (guardian-docs/04-api/TRIPS_BOARDING_API.md), and translating between the two shapes at the
 *     boundary is one more place for "both" and "unknown" to be confused.
 * @param reason optional, always. Requiring a parent to justify their child's absence is friction
 *     with no safety value (BR-ABS-001).
 */
public record Absence(
    UUID id,
    UUID studentId,
    UUID declaredByGuardianId,
    LocalDate fromDate,
    LocalDate toDate,
    Direction direction,
    String reason,
    Status status) {

  public Absence {
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(fromDate, "fromDate");
    Objects.requireNonNull(toDate, "toDate");
    Objects.requireNonNull(status, "status");

    if (toDate.isBefore(fromDate)) {
      throw new IllegalArgumentException("toDate must not precede fromDate");
    }
  }

  /** Which run the declaration covers. Null on {@link Absence#direction} means both. */
  public enum Direction {
    PICKUP,
    DROP
  }

  /**
   * Cancellation is a status, never a delete.
   *
   * <p>A manifest was materialised from this declaration, so the reason a child was excluded from a
   * trip has to stay answerable after the fact (BR-ABS-004).
   */
  public enum Status {
    ACTIVE,
    CANCELLED
  }

  /** Whether this declaration covers a given date and run. */
  public boolean covers(LocalDate date, Direction run) {
    if (status != Status.ACTIVE) {
      return false;
    }
    boolean inRange = !date.isBefore(fromDate) && !date.isAfter(toDate);
    return inRange && (direction == null || direction == run);
  }
}
