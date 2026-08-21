package com.guardian.fleet.application.command;

import com.guardian.fleet.domain.SeatingCapacity;
import com.guardian.fleet.domain.VehicleId;
import java.util.Objects;
import java.util.UUID;

/** Input to {@link com.guardian.fleet.application.usecase.UpdateVehicleUseCase} (FLT-001). */
public record UpdateVehicleCommand(
    VehicleId vehicleId,
    String displayName,
    SeatingCapacity seatingCapacity,
    String vendorName,
    UUID actorId,
    String actorRole) {

  public UpdateVehicleCommand {
    Objects.requireNonNull(vehicleId, "vehicleId");
    Objects.requireNonNull(displayName, "displayName");
    Objects.requireNonNull(seatingCapacity, "seatingCapacity");
  }
}
