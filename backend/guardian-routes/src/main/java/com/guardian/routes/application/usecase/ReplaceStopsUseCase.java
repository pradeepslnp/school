package com.guardian.routes.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.routes.application.command.ReplaceStopsCommand;
import com.guardian.routes.application.command.StopInput;
import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.application.port.RouteStudentAssignmentRepository;
import com.guardian.routes.application.port.StopRepository;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.Stop;
import com.guardian.routes.domain.StopId;
import java.time.LocalTime;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Replaces a route's full stop list (feature RTE-001, {@code PUT /routes/{id}/stops}).
 *
 * <p>Always the full ordered list, never a single-stop edit — matching FLEET_STAFF_ROUTES_API.md's
 * own reasoning: partial stop edits invite sequence gaps and ordering bugs. Validation runs here,
 * across the whole set, because "are times increasing" and "are there at least two stops" are facts
 * about the set, not about any one stop.
 *
 * <p><strong>A kept stop keeps its id.</strong> The list names each existing stop it keeps by id;
 * that stop is updated in place, so every student assigned to it stays assigned to it. A stop
 * without an id is new. An existing stop left out of the list is removed (deactivated, never
 * deleted, because trips that already ran reference it) — but not while a student is still assigned
 * to it (BR-ROUTE-009): the office moves those students first, so no child is left pointing at a
 * stop the bus no longer makes.
 */
@Service
@BusinessRule({"BR-ROUTE-001", "BR-ROUTE-003", "BR-ROUTE-008", "BR-ROUTE-009"})
public class ReplaceStopsUseCase {

  private static final int MINIMUM_STOPS = 2;

  private final RouteRepository routeRepository;
  private final StopRepository stopRepository;
  private final RouteStudentAssignmentRepository assignments;
  private final AuditPort auditPort;

  public ReplaceStopsUseCase(
      RouteRepository routeRepository,
      StopRepository stopRepository,
      RouteStudentAssignmentRepository assignments,
      AuditPort auditPort) {
    this.routeRepository = routeRepository;
    this.stopRepository = stopRepository;
    this.assignments = assignments;
    this.auditPort = auditPort;
  }

  @Transactional
  public List<Stop> execute(ReplaceStopsCommand command) {
    TenantId tenantId = TenantContext.require();

    Route route =
        routeRepository
            .findById(command.routeId())
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.ROUTE_NOT_FOUND,
                        "BR-ROUTE-001",
                        Map.of("routeId", command.routeId().toString())));

    // BR-ROUTE-001: at least two stops.
    if (command.stops().size() < MINIMUM_STOPS) {
      throw new BusinessRuleViolationException(
          ErrorCode.ROUTE_MINIMUM_STOPS_REQUIRED,
          "BR-ROUTE-001",
          Map.of("stopCount", command.stops().size()));
    }

    List<StopInput> ordered =
        command.stops().stream().sorted((a, b) -> a.sequenceNo() - b.sequenceNo()).toList();

    // BR-ROUTE-008: strictly increasing times in the order each run visits the stops. The morning
    // run follows the sequence; the afternoon run travels back from school, so the last stop in
    // the sequence is dropped first and drop times increase in reverse.
    assertIncreasing(ordered, StopInput::scheduledPickupTime);
    assertIncreasing(ordered.reversed(), StopInput::scheduledDropTime);

    // Every id sent must be one of this route's current stops, each at most once. Anything else
    // is a stale or foreign id, and updating it would move a stop between routes.
    Set<StopId> current =
        stopRepository.findByRoute(route.id()).stream().map(Stop::id).collect(Collectors.toSet());
    Set<StopId> kept = new HashSet<>();
    for (StopInput input : ordered) {
      if (input.id() != null && (!current.contains(input.id()) || !kept.add(input.id()))) {
        throw new BusinessRuleViolationException(
            ErrorCode.ROUTE_STOP_NOT_FOUND,
            "BR-ROUTE-002",
            Map.of("stopId", input.id().value().toString()));
      }
    }

    // BR-ROUTE-009: a stop a student is assigned to is not removed out from under them.
    Set<UUID> removed =
        current.stream()
            .filter(id -> !kept.contains(id))
            .map(StopId::value)
            .collect(Collectors.toSet());
    List<UUID> stillAssigned = assignments.stopsWithActiveAssignments(removed);
    if (!stillAssigned.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.ROUTE_STOP_HAS_ASSIGNED_STUDENTS,
          "BR-ROUTE-009",
          Map.<String, Object>of(
              "stopIds", stillAssigned.stream().map(UUID::toString).sorted().toList()));
    }

    List<Stop> stops =
        ordered.stream()
            .map(
                input ->
                    new Stop(
                        input.id() != null ? input.id() : StopId.generate(),
                        input.sequenceNo(),
                        input.name(),
                        input.latitude(),
                        input.longitude(),
                        input.geofenceRadiusM(),
                        input.scheduledPickupTime(),
                        input.scheduledDropTime(),
                        input.landmark()))
            .toList();

    stopRepository.replaceAll(route.id(), stops);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ROUTE_STOPS_REPLACED")
            .subject("Route", route.id().value())
            .after(
                Map.of(
                    "stopCount", stops.size(),
                    "kept", kept.size(),
                    "added", stops.size() - kept.size(),
                    "removed", removed.size()))
            .build());

    return stops;
  }

  private static void assertIncreasing(
      List<StopInput> ordered, java.util.function.Function<StopInput, LocalTime> timeOf) {
    LocalTime previous = null;
    for (StopInput stop : ordered) {
      LocalTime current = timeOf.apply(stop);
      if (current == null) {
        continue;
      }
      if (previous != null && !current.isAfter(previous)) {
        throw new BusinessRuleViolationException(
            ErrorCode.ROUTE_STOP_TIMES_NOT_INCREASING,
            "BR-ROUTE-008",
            Map.of("sequenceNo", stop.sequenceNo()));
      }
      previous = current;
    }
  }
}
