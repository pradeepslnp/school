package com.guardian.routes.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.routes.application.command.CreateRouteCommand;
import com.guardian.routes.application.command.ReplaceStopsCommand;
import com.guardian.routes.application.command.StopInput;
import com.guardian.routes.application.command.UpdateRouteCommand;
import com.guardian.routes.application.usecase.CreateRouteUseCase;
import com.guardian.routes.application.usecase.ListRoutesUseCase;
import com.guardian.routes.application.usecase.ListStopsUseCase;
import com.guardian.routes.application.usecase.ReplaceStopsUseCase;
import com.guardian.routes.application.usecase.UpdateRouteUseCase;
import com.guardian.routes.domain.OperatingDays;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.SchoolId;
import com.guardian.routes.domain.StopId;
import com.guardian.routes.domain.VehicleId;
import com.guardian.routes.interfaces.rest.dto.CreateRouteRequest;
import com.guardian.routes.interfaces.rest.dto.ReplaceStopsRequest;
import com.guardian.routes.interfaces.rest.dto.RouteResponse;
import com.guardian.routes.interfaces.rest.dto.StopResponse;
import com.guardian.routes.interfaces.rest.dto.UpdateRouteRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
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
  private final UpdateRouteUseCase updateRoute;
  private final ReplaceStopsUseCase replaceStops;
  private final ListStopsUseCase listStops;

  public RouteController(
      CreateRouteUseCase createRoute,
      ListRoutesUseCase listRoutes,
      UpdateRouteUseCase updateRoute,
      ReplaceStopsUseCase replaceStops,
      ListStopsUseCase listStops) {
    this.createRoute = createRoute;
    this.listRoutes = listRoutes;
    this.updateRoute = updateRoute;
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
            request.operatingDays() == null ? null : OperatingDays.parse(request.operatingDays()),
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
                            stop.id() == null ? null : StopId.of(stop.id()),
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

  /**
   * Edits a route (feature RTE-001).
   *
   * <p>{@code PATCH}, and every field optional: an operator changing only the operating days should
   * not have to resend the name and the default vehicle, and a client that did would overwrite a
   * colleague's concurrent rename with a stale value it never meant to send.
   *
   * <p>The route's code, school and active flag are not editable — see {@code UpdateRouteUseCase}
   * for why, and BR-ROUTE-007 for what deactivation is waiting on.
   */
  @PatchMapping("/{routeId}")
  @RequiresPermission("PERM-ROUTE-MANAGE")
  public RouteResponse update(
      @PathVariable UUID routeId,
      @Valid @RequestBody UpdateRouteRequest request,
      CurrentActor actor) {

    UpdateRouteCommand command =
        new UpdateRouteCommand(
            RouteId.of(routeId),
            request.name(),
            request.defaultVehicleId() == null ? null : VehicleId.of(request.defaultVehicleId()),
            request.operatingDays() == null ? null : OperatingDays.parse(request.operatingDays()),
            actor.userId(),
            actor.role());

    return RouteResponse.from(updateRoute.execute(command));
  }
}
