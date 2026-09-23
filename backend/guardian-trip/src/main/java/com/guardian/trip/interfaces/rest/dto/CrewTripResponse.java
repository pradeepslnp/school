package com.guardian.trip.interfaces.rest.dto;

import com.guardian.trip.application.port.CrewTrip;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * One of the crew's runs, as the driver app reads it (`GET /trips/mine`).
 *
 * <p>Carries the route's identity and the bus the route normally runs, because a {@code DRIVER}
 * holds no {@code PERM-VEHICLE-VIEW} and therefore cannot fetch either separately. {@code
 * expectedVehicle*} is null when the route has no default vehicle — the app must then tell the
 * driver to call the transport manager rather than offer a start it knows will be refused.
 */
public record CrewTripResponse(
    UUID id,
    UUID routeId,
    String routeCode,
    String routeName,
    String stopCount,
    LocalDate serviceDate,
    String direction,
    String status,
    LocalTime scheduledStartTime,
    Instant startedAt,
    Instant endedAt,
    UUID vehicleId,
    UUID expectedVehicleId,
    String expectedVehicleDisplayName,
    String expectedVehicleRegistrationNo,
    String cancelledReason) {

  public static CrewTripResponse from(CrewTrip crewTrip) {
    return new CrewTripResponse(
        crewTrip.trip().id(),
        crewTrip.trip().routeId(),
        crewTrip.routeCode(),
        crewTrip.routeName(),
        crewTrip.stopCount(),
        crewTrip.trip().serviceDate(),
        crewTrip.trip().direction().name(),
        crewTrip.trip().status().name(),
        crewTrip.trip().scheduledStartTime(),
        crewTrip.trip().startedAt(),
        crewTrip.trip().endedAt(),
        crewTrip.trip().vehicleId(),
        crewTrip.expectedVehicleId(),
        crewTrip.expectedVehicleDisplayName(),
        crewTrip.expectedVehicleRegistrationNo(),
        crewTrip.trip().cancelledReason());
  }
}
