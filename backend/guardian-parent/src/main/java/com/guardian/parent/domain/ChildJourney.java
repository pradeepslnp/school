package com.guardian.parent.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * One child's current status, as the parent dashboard shows it (P-02).
 *
 * <p>Every time is an {@link Instant} — UTC, with no zone folded in. The zone travels once per
 * response in {@code meta.school} (BR-CFG-006); baking it into each field would be the same fact
 * repeated N times with N chances to disagree.
 *
 * <p>Nulls are meaningful here and are not defaults. A null {@code estimatedArrival} means no
 * estimate exists, which the app renders as an absent line rather than as a guess.
 *
 * @param vehicleDisplayName what the parent calls the bus — "Bus 12", never a registration number
 * @param tripId the trip carrying this child now, or null. Non-null only when {@link
 *     JourneyState#permitsLiveTracking()} holds, so P-04 has nothing to open when tracking is not
 *     permitted.
 * @param positionReceivedAt when the vehicle's last position was received. The client derives
 *     freshness from this against the response timestamp rather than the device clock, so a phone
 *     running five minutes fast does not report a five-minute-stale bus.
 * @param positionStale the server's own staleness verdict (BR-TRACK-003), which is authoritative:
 *     it sees ingestion lag and rejected reports that an age computed from timestamps cannot.
 */
public record ChildJourney(
    UUID studentId,
    String displayName,
    String className,
    JourneyState state,
    UUID tripId,
    String vehicleDisplayName,
    String stopName,
    Instant lastEventAt,
    Instant estimatedArrival,
    Instant nextDepartureAt,
    Instant positionReceivedAt,
    Boolean positionStale) {

  public ChildJourney {
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(displayName, "displayName");
    Objects.requireNonNull(state, "state");
  }
}
