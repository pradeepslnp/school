package com.guardian.fleet.interfaces.rest.dto;

import com.guardian.fleet.domain.Vehicle;
import java.util.UUID;

/** Wire representation of a vehicle. A domain object is never serialised directly to a client. */
public record VehicleResponse(
    UUID id,
    UUID schoolId,
    String registrationNo,
    String displayName,
    String vehicleType,
    int seatingCapacity,
    String vendorName,
    String status) {

  public static VehicleResponse from(Vehicle vehicle) {
    return new VehicleResponse(
        vehicle.id().value(),
        vehicle.schoolId().value(),
        vehicle.registrationNo().value(),
        vehicle.displayName(),
        vehicle.vehicleType().name(),
        vehicle.seatingCapacity().seats(),
        vehicle.vendorName().orElse(null),
        vehicle.status().name());
  }
}
