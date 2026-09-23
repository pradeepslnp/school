package com.guardian.routes.interfaces.rest.dto;

import com.guardian.routes.domain.Route;
import java.util.UUID;

/** Wire representation of a route. A domain object is never serialised directly to a client. */
public record RouteResponse(
    UUID id,
    UUID schoolId,
    String code,
    String name,
    UUID defaultVehicleId,
    String operatingDays,
    boolean active) {

  public static RouteResponse from(Route route) {
    return new RouteResponse(
        route.id().value(),
        route.schoolId().value(),
        route.code(),
        route.name(),
        route.defaultVehicleId().map(id -> id.value()).orElse(null),
        route.operatingDays().toStoredValue(),
        route.active());
  }
}
