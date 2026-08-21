package com.guardian.parent.domain;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;

/**
 * One past leg — a single morning or afternoon journey on a single day (P-05).
 *
 * <p>The durable record a parent scrolls back through. It is built from {@code boarding_events},
 * which is append-only and is the evidence, rather than from any summary table: a summary would be
 * a second version of what happened, and the two would eventually disagree.
 *
 * @param serviceDate the school day this leg belongs to. A {@link LocalDate}, not an instant — a
 *     school day is a calendar fact, and an instant would put the boundary in the wrong day for any
 *     school not on UTC (BR-CFG-006).
 * @param eventAt the terminal event on the leg, in UTC. Null where the leg produced no boarding
 *     record at all, which is itself the story on a no-show.
 */
public record JourneyHistoryEntry(
    LocalDate serviceDate,
    JourneyLeg.Direction direction,
    JourneyState state,
    String vehicleDisplayName,
    String stopName,
    Instant eventAt) {

  public JourneyHistoryEntry {
    Objects.requireNonNull(serviceDate, "serviceDate");
    Objects.requireNonNull(direction, "direction");
    Objects.requireNonNull(state, "state");
  }
}
