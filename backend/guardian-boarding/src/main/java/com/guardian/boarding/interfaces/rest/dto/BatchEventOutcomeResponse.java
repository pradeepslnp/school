package com.guardian.boarding.interfaces.rest.dto;

import com.guardian.boarding.application.result.BatchEventOutcome;
import java.util.UUID;

/**
 * One event's outcome in a sync batch.
 *
 * <p>Field names and status values are what the driver app's {@code OutboundTransport} already
 * parses, and what TRIPS_BOARDING_API.md documents: {@code CREATED}, {@code DUPLICATE},
 * {@code FLAGGED_FOR_REVIEW}. The client treats {@code DUPLICATE} as a success — it means an
 * earlier attempt did reach the server and the idempotency key did its job.
 */
public record BatchEventOutcomeResponse(
    UUID clientEventId, String status, UUID eventId, String reason) {

  public static BatchEventOutcomeResponse from(BatchEventOutcome outcome) {
    return new BatchEventOutcomeResponse(
        outcome.clientEventId(),
        outcome.status().name(),
        outcome.eventId(),
        outcome.reason());
  }
}
