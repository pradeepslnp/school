package com.guardian.routes.application.command;

import com.guardian.routes.domain.RouteId;
import java.util.List;
import java.util.UUID;

/** Input to {@code ReplaceStopsUseCase} (feature RTE-001). */
public record ReplaceStopsCommand(
    RouteId routeId, List<StopInput> stops, UUID actorId, String actorRole) {}
