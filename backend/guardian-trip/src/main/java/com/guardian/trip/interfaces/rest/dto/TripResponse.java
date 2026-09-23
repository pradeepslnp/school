package com.guardian.trip.interfaces.rest.dto;

import com.guardian.trip.domain.Trip;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Wire form of a trip (documentation/04-api/TRIPS_BOARDING_API.md).
 *
 * <p>A response record, not the domain type: serialising {@link Trip} directly would make every
 * future field rename a breaking API change.
 */
public record TripResponse(
    UUID id,
    UUID schoolId,
    UUID routeId,
    UUID vehicleId,
    LocalDate serviceDate,
    String direction,
    String status,
    LocalTime scheduledStartTime,
    Instant startedAt,
    Instant endedAt,
    Instant closedAt,
    String cancelledReason) {

  public static TripResponse from(Trip trip) {
    return new TripResponse(
        trip.id(),
        trip.schoolId(),
        trip.routeId(),
        trip.vehicleId(),
        trip.serviceDate(),
        trip.direction().name(),
        trip.status().name(),
        trip.scheduledStartTime(),
        trip.startedAt(),
        trip.endedAt(),
        trip.closedAt(),
        trip.cancelledReason());
  }
}
