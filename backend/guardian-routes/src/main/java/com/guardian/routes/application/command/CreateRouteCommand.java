package com.guardian.routes.application.command;

import com.guardian.routes.domain.OperatingDays;
import com.guardian.routes.domain.SchoolId;
import com.guardian.routes.domain.VehicleId;
import java.util.UUID;

/**
 * Input to {@code CreateRouteUseCase} (feature RTE-001).
 *
 * @param operatingDays null defaults to the five-day school week. Optional rather than required so
 *     an operator creating a route in the ordinary case does not have to state the obvious — and so
 *     every route created before V22 has the same value as one created after it.
 */
public record CreateRouteCommand(
    SchoolId schoolId,
    String code,
    String name,
    VehicleId defaultVehicleId,
    OperatingDays operatingDays,
    UUID actorId,
    String actorRole) {}
