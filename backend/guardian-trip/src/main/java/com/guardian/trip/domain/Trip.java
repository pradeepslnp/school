package com.guardian.trip.domain;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Objects;
import java.util.UUID;

/**
 * One execution of one route, on one date, in one direction (BR-TRIP-001).
 *
 * <p>This record is the anchor for every safety event the platform holds. A boarding event, a
 * handover, a position report and a reconciliation item all point at a trip id; a child's journey
 * state is derived from the trip's status joined to their manifest row. Nothing else in the domain
 * has that many dependants, which is why the invariants live here rather than in the use cases.
 *
 * @param vehicleId null until the trip starts. The vehicle is chosen at start, not at generation:
 *     recording an intended bus as fact would misreport which vehicle a child actually boarded when
 *     the yard substitutes one that morning (V5 says the same thing at the column).
 * @param scheduledStartTime the timetable's expectation, in the school's wall clock. Null only for
 *     a trip created outside the timetable.
 * @param startedAt server time, always. {@code deviceStartedAt} is the driver's phone clock, kept
 *     beside it for reference (BR-TRIP-008): a handset with a wrong clock must not be able to move
 *     a safety record in time.
 */
public record Trip(
    UUID id,
    UUID schoolId,
    UUID routeId,
    UUID vehicleId,
    LocalDate serviceDate,
    TripDirection direction,
    TripStatus status,
    LocalTime scheduledStartTime,
    Instant startedAt,
    Instant endedAt,
    Instant closedAt,
    Instant deviceStartedAt,
    String cancelledReason) {

  public Trip {
    Objects.requireNonNull(schoolId, "schoolId");
    Objects.requireNonNull(routeId, "routeId");
    Objects.requireNonNull(serviceDate, "serviceDate");
    Objects.requireNonNull(direction, "direction");
    Objects.requireNonNull(status, "status");

    if (status == TripStatus.IN_PROGRESS && vehicleId == null) {
      throw new IllegalArgumentException("a trip in progress must carry the vehicle running it");
    }
    if (endedAt != null && startedAt != null && endedAt.isBefore(startedAt)) {
      throw new IllegalArgumentException("endedAt must not precede startedAt");
    }
  }

  /** True once the run is over, whatever the reason — nothing may be recorded against it. */
  public boolean isTerminal() {
    return status.isTerminal();
  }

  /**
   * Whether boarding and alighting may still be recorded against this trip.
   *
   * <p>MOD-09 asks this before writing any event. Deliberately narrower than "not terminal": a
   * trip that has not started has no manifest yet, and a completed one has had its records closed
   * by the crew — a late event against either is a correction, which carries a reason and an actor,
   * not an ordinary write (BR-BOARD-001).
   */
  public boolean acceptsBoardingEvents() {
    return status == TripStatus.IN_PROGRESS;
  }
}
