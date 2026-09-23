package com.guardian.trip.application.command;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * A crew member's request to begin a run.
 *
 * @param vehicleId the bus actually being driven — chosen now, not at generation, because the yard
 *     substitutes vehicles and the record must say which one carried the children (BR-TRIP-004).
 * @param deviceStartedAt the handset's clock when the driver tapped start, or null from a caller
 *     that has none. Stored beside the server's own timestamp, never instead of it (BR-TRIP-008):
 *     an offline-first client (ADR-0008) may sync hours later, and a phone with a wrong clock must
 *     not be able to move a safety record in time.
 */
public record StartTripCommand(
    UUID tripId,
    UUID vehicleId,
    Instant deviceStartedAt,
    UUID actorUserId,
    String actorRole) {

  public StartTripCommand {
    Objects.requireNonNull(tripId, "tripId");
    Objects.requireNonNull(actorUserId, "actorUserId");
    Objects.requireNonNull(actorRole, "actorRole");
  }
}
