package com.guardian.boarding.application.result;

import java.util.UUID;

/**
 * What became of one event in an offline sync batch (BRD-004, BR-SAFE-005 🔴).
 *
 * <p>There is no "rejected" outcome, and that absence is the rule: a safety event recorded offline
 * is never discarded. Where it contradicts server state — the child was marked absent after the
 * handset cached the manifest, or the trip has since ended — the record is written anyway and
 * flagged, because losing a real record of a child boarding a bus is worse than keeping a
 * questionable one.
 *
 * @param reason set only on {@link Status#FLAGGED_FOR_REVIEW}: what the conflict was, for the
 *     person who will look at it.
 */
public record BatchEventOutcome(UUID clientEventId, Status status, UUID eventId, String reason) {

  public enum Status {
    /** Written for the first time. */
    CREATED,
    /** The idempotency key was already known — an earlier attempt did reach the server. */
    DUPLICATE,
    /** Written, and contradicting server state. A person decides what it means. */
    FLAGGED_FOR_REVIEW
  }

  public static BatchEventOutcome created(UUID clientEventId, UUID eventId) {
    return new BatchEventOutcome(clientEventId, Status.CREATED, eventId, null);
  }

  public static BatchEventOutcome duplicate(UUID clientEventId, UUID eventId) {
    return new BatchEventOutcome(clientEventId, Status.DUPLICATE, eventId, null);
  }

  public static BatchEventOutcome flagged(UUID clientEventId, UUID eventId, String reason) {
    return new BatchEventOutcome(clientEventId, Status.FLAGGED_FOR_REVIEW, eventId, reason);
  }
}
