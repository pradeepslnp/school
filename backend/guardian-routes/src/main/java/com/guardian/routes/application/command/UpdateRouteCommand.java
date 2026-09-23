package com.guardian.routes.application.command;

import com.guardian.routes.domain.OperatingDays;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.VehicleId;
import java.util.UUID;

/**
 * Input to {@code UpdateRouteUseCase} (feature RTE-001).
 *
 * <p>Every editable field is nullable and null means <strong>leave unchanged</strong> — the
 * semantics of a {@code PATCH}. The route's {@code code}, its school, and its active flag are
 * absent entirely rather than present-and-ignored: a field a caller can send and have silently
 * discarded is worse than one the contract never offered. See {@code Route#withEdits} for why
 * deactivation in particular waits for BR-ROUTE-007.
 */
public record UpdateRouteCommand(
    RouteId routeId,
    String name,
    VehicleId defaultVehicleId,
    OperatingDays operatingDays,
    UUID actorId,
    String actorRole) {}
