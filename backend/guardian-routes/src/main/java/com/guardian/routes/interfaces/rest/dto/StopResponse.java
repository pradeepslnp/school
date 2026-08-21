package com.guardian.routes.interfaces.rest.dto;

import com.guardian.routes.domain.Stop;
import java.time.LocalTime;
import java.util.UUID;

/** Wire representation of a stop. A domain object is never serialised directly to a client. */
public record StopResponse(
    UUID id,
    int sequenceNo,
    String name,
    double latitude,
    double longitude,
    int geofenceRadiusM,
    LocalTime scheduledPickupTime,
    LocalTime scheduledDropTime,
    String landmark) {

  public static StopResponse from(Stop stop) {
    return new StopResponse(
        stop.id().value(),
        stop.sequenceNo(),
        stop.name(),
        stop.latitude(),
        stop.longitude(),
        stop.geofenceRadiusM(),
        stop.scheduledPickupTime().orElse(null),
        stop.scheduledDropTime().orElse(null),
        stop.landmark().orElse(null));
  }
}
