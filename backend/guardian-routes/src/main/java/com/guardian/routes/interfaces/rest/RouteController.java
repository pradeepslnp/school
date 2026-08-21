package com.guardian.routes.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.routes.application.command.CreateRouteCommand;
import com.guardian.routes.application.command.ReplaceStopsCommand;
import com.guardian.routes.application.command.StopInput;
import com.guardian.routes.application.usecase.CreateRouteUseCase;
import com.guardian.routes.application.usecase.ListRoutesUseCase;
import com.guardian.routes.application.usecase.ListStopsUseCase;
import com.guardian.routes.application.usecase.ReplaceStopsUseCase;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.SchoolId;
import com.guardian.routes.domain.VehicleId;
import com.guardian.routes.interfaces.rest.dto.CreateRouteRequest;
import com.guardian.routes.interfaces.rest.dto.ReplaceStopsRequest;
import com.guardian.routes.interfaces.rest.dto.RouteResponse;
import com.guardian.routes.interfaces.rest.dto.StopResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Route endpoints (feature RTE-001). See guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md.
 *
 * <p>Every method declares a permission from the permission matrix — an architecture test fails the
 * build for any endpoint that does not (BR-IAM-002). This layer only translates: parse the wire
 * format into domain types, call one use case, map the result back.
 */
@RestController
@RequestMapping("/api/v1/routes")
public class RouteController {

  private final CreateRouteUseCase createRoute;
  private final ListRoutesUseCase listRoutes;
  private final ReplaceStopsUseCase replaceStops;
  private final ListStopsUseCase listStops;

  public RouteController(
      CreateRouteUseCase createRoute,
      ListRoutesUseCase listRoutes,
      ReplaceStopsUseCase replaceStops,
      ListStopsUseCase listStops) {
    this.createRoute = createRoute;
    this.listRoutes = listRoutes;
    this.replaceStops = replaceStops;
    this.listStops = listStops;
  }

  @PostMapping
  @RequiresPermission("PERM-ROUTE-MANAGE")
  public ResponseEntity<RouteResponse> create(
      @Valid @RequestBody CreateRouteRequest request, CurrentActor actor) {

    CreateRouteCommand command =
        new CreateRouteCommand(
            SchoolId.of(request.schoolId()),
            request.code(),
            request.name(),
            request.defaultVehicleId() == null ? null : VehicleId.of(request.defaultVehicleId()),
            actor.userId(),
            actor.role());

    Route created = createRoute.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/routes/" + created.id()))
        .body(RouteResponse.from(created));
  }

  @GetMapping
  @RequiresPermission("PERM-ROUTE-VIEW")
  public List<RouteResponse> listBySchool(@RequestParam UUID schoolId) {
    return listRoutes.bySchool(SchoolId.of(schoolId)).stream().map(RouteResponse::from).toList();
  }

  @PutMapping("/{routeId}/stops")
  @RequiresPermission("PERM-ROUTE-MANAGE")
  public List<StopResponse> replaceStops(
      @PathVariable UUID routeId,
      @Valid @RequestBody ReplaceStopsRequest request,
      CurrentActor actor) {

    ReplaceStopsCommand command =
        new ReplaceStopsCommand(
            RouteId.of(routeId),
            request.stops().stream()
                .map(
                    stop ->
                        new StopInput(
                            stop.sequenceNo(),
                            stop.name(),
                            stop.latitude(),
                            stop.longitude(),
                            stop.geofenceRadiusM(),
                            stop.scheduledPickupTime(),
                            stop.scheduledDropTime(),
                            stop.landmark()))
                .toList(),
            actor.userId(),
            actor.role());

    return replaceStops.execute(command).stream().map(StopResponse::from).toList();
  }

  @GetMapping("/{routeId}/stops")
  @RequiresPermission("PERM-ROUTE-VIEW")
  public List<StopResponse> getStops(@PathVariable UUID routeId) {
    return listStops.forRoute(RouteId.of(routeId)).stream().map(StopResponse::from).toList();
  }
}
