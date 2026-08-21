package com.guardian.routes.application.command;

import com.guardian.routes.domain.SchoolId;
import com.guardian.routes.domain.VehicleId;
import java.util.UUID;

/** Input to {@code CreateRouteUseCase} (feature RTE-001). */
public record CreateRouteCommand(
    SchoolId schoolId,
    String code,
    String name,
    VehicleId defaultVehicleId,
    UUID actorId,
    String actorRole) {}
