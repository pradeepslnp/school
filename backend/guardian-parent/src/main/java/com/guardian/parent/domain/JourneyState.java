package com.guardian.parent.domain;

/**
 * Where a child is in their journey right now.
 *
 * <p>This is the answer the parent app exists to give, and P-02 renders it without a tap
 * (guardian-docs/05-ui/PARENT_APP.md).
 *
 * <p>It is <strong>derived, never stored</strong>. No table holds a column called "journey state":
 * it is computed from today's trip status, the child's manifest row, their boarding events, and any
 * declared absence. Storing it would create a second source of truth that drifts from the boarding
 * record — and the boarding record is the evidence.
 *
 * <p>The wire form is {@code SCREAMING_SNAKE_CASE} ({@link #wireName()}), matching
 * guardian-docs/04-api/API_STANDARDS.md. New values ship additively within {@code v1}; the parent
 * app renders an unrecognised one as explicitly unknown rather than mapping it onto the nearest
 * familiar state, so a state added after a build shipped can never be displayed as something
 * reassuring.
 */
public enum JourneyState {

  /** No trip today, or between trips. The calm state, not the empty one. */
  AT_REST,

  /** A trip exists for today and has not started. */
  SCHEDULED,

  /** The trip is running and this child has not boarded yet. */
  AWAITING_BOARDING,

  /** On the vehicle: a BOARD event with no matching ALIGHT. */
  ON_BOARD,

  /** Alighted at the school on a pickup trip. */
  ARRIVED_AT_SCHOOL,

  /** Alighted at their stop on a drop trip. */
  HANDED_OVER,

  /** The trip passed their stop without a boarding record (BR-SAFE-002). */
  NO_SHOW,

  /** A guardian declared the child not travelling (BR-ABS-001). */
  ABSENT,

  /**
   * Boarded, and the trip closed with no record of getting off (BR-SAFE-001 🔴).
   *
   * <p>The one state that dominates the parent's screen, because it is the one that requires them
   * to act now.
   */
  UNACCOUNTED;

  /** The value as it appears on the wire. */
  public String wireName() {
    return name();
  }

  /**
   * Whether live tracking is offered for a child in this state.
   *
   * <p>Tracking is trip-scoped (BR-TRACK-001): vehicles are not tracked outside a trip, which is
   * what keeps the platform a safety tool rather than staff surveillance. Deciding it here rather
   * than in the client means every surface agrees.
   */
  public boolean permitsLiveTracking() {
    return this == ON_BOARD || this == AWAITING_BOARDING;
  }
}
