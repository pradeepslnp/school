package com.guardian.trip.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

/**
 * The crew's start request.
 *
 * @param vehicleId required — a trip cannot start without naming the bus that is running it
 *     (BR-TRIP-004). Validated here so the caller gets a field-level 400 rather than a rule
 *     violation for something the form should have caught.
 * @param deviceStartedAt optional: the handset's own clock. Sent by the driver app, absent from a
 *     manager starting a trip from the console. Never used in place of server time (BR-TRIP-008).
 */
public record StartTripRequest(@NotNull UUID vehicleId, Instant deviceStartedAt) {}
