package com.guardian.trip.domain;

import java.util.EnumSet;
import java.util.Set;

/**
 * The lifecycle of one trip (BR-TRIP-002).
 *
 * <p><strong>Known divergence from BUSINESS_RULES.md, recorded rather than resolved
 * silently.</strong>
 * BR-TRIP-002 names five forward states, including a {@code STARTED} between {@code SCHEDULED} and
 * {@code IN_PROGRESS}. The schema's {@code ck_trips_status} (V5) permits only {@code SCHEDULED},
 * {@code IN_PROGRESS}, {@code COMPLETED}, {@code CLOSED} and {@code CANCELLED}, and nothing else in
 * the design distinguishes "started" from "in progress" — there is no event between them and no
 * screen that renders them differently. This enum follows the schema. Adding a sixth value to a
 * CHECK constraint to satisfy a rule no behaviour depends on would create a state the product
 * cannot explain; the rule text is what should change, and that is flagged in
 * IMPLEMENTATION_STATUS.md rather than edited here (CLAUDE.md §17 — surface the conflict, do not
 * quietly amend the lower document).
 *
 * <p>Transitions are declared here, in the domain, rather than checked inside each use case: a
 * transition table in one place is auditable by reading it, while the same rule spread across four
 * use cases is four places for it to drift.
 */
public enum TripStatus {

  /** Generated for an operating day, not yet under way (BR-TRIP-011). */
  SCHEDULED,

  /** A crew has started it: vehicle assigned, manifest materialised (BR-TRIP-003). */
  IN_PROGRESS,

  /** The crew ended the run. Boarding records are final; reconciliation has not run. */
  COMPLETED,

  /** Reconciliation completed — every child on the manifest is accounted for (BR-SAFE-001). */
  CLOSED,

  /** The run will not happen. Reachable before it ends, never after (BR-TRIP-007). */
  CANCELLED;

  /**
   * Whether this status may become {@code target}.
   *
   * <p>No status may transition to itself: re-starting an in-progress trip, or closing a closed
   * one, is a duplicate request and the caller is told so rather than silently succeeding.
   */
  public boolean canTransitionTo(TripStatus target) {
    return switch (this) {
      case SCHEDULED -> EnumSet.of(IN_PROGRESS, CANCELLED).contains(target);
      case IN_PROGRESS -> EnumSet.of(COMPLETED, CANCELLED).contains(target);
      case COMPLETED -> target == CLOSED;
      case CLOSED, CANCELLED -> false;
    };
  }

  /** The statuses a trip can still move to — used to explain a refusal, not to decide one. */
  public Set<TripStatus> allowedNext() {
    EnumSet<TripStatus> allowed = EnumSet.noneOf(TripStatus.class);
    for (TripStatus candidate : values()) {
      if (canTransitionTo(candidate)) {
        allowed.add(candidate);
      }
    }
    return allowed;
  }

  /** True once the run is over, whatever the reason. Nothing may be recorded against it. */
  public boolean isTerminal() {
    return this == CLOSED || this == CANCELLED;
  }
}
