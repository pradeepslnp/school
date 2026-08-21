package com.guardian.fleet.application.command;

import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.SeatingCapacity;
import com.guardian.fleet.domain.VehicleType;
import java.util.Objects;
import java.util.UUID;

/** Input to {@link com.guardian.fleet.application.usecase.CreateVehicleUseCase} (FLT-001). */
public record CreateVehicleCommand(
    SchoolId schoolId,
    RegistrationNo registrationNo,
    String displayName,
    VehicleType vehicleType,
    SeatingCapacity seatingCapacity,
    String vendorName,
    UUID actorId,
    String actorRole) {

  public CreateVehicleCommand {
    Objects.requireNonNull(schoolId, "schoolId");
    Objects.requireNonNull(registrationNo, "registrationNo");
    Objects.requireNonNull(displayName, "displayName");
    Objects.requireNonNull(vehicleType, "vehicleType");
    Objects.requireNonNull(seatingCapacity, "seatingCapacity");
  }
}
