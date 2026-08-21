package com.guardian.parent.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * One leg of a child's day — the morning pickup or the afternoon drop — as P-03 lists it.
 *
 * <p>A leg describes a plan and what happened on it, which is why it is separate from the live
 * fields on {@link ChildJourney}. A child can be at rest, with a completed morning leg behind them
 * and a scheduled afternoon leg ahead; collapsing those into one "current" value is what makes a
 * dashboard say "At school" and tell the parent nothing about the bus home.
 */
public record JourneyLeg(
    UUID tripId,
    Direction direction,
    JourneyState state,
    String vehicleDisplayName,
    String stopName,
    /* When this leg is due to start, in UTC. Built from the stop's school-local schedule. */
    Instant scheduledAt,
    /* The most recent boarding or alighting event on this leg. */
    Instant eventAt) {

  public JourneyLeg {
    Objects.requireNonNull(direction, "direction");
    Objects.requireNonNull(state, "state");
  }

  /**
   * Which half of the day a leg belongs to.
   *
   * <p>Named for the operation rather than the clock: {@code PICKUP} is the run that collects
   * children, {@code DROP} the run that returns them, which is the vocabulary the trips table and
   * the driver app already use.
   */
  public enum Direction {
    PICKUP,
    DROP;

    public String wireName() {
      // MORNING/AFTERNOON on the wire, because that is what a parent reads on P-03. The
      // operational names stay internal.
      return this == PICKUP ? "MORNING" : "AFTERNOON";
    }
  }
}
