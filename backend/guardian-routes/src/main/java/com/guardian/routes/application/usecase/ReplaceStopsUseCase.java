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
import com.guardian.routes.application.port.StopRepository;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.Stop;
import com.guardian.routes.domain.StopId;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Replaces a route's full stop list (feature RTE-001, {@code PUT /routes/{id}/stops}).
 *
 * <p>Always the full ordered list, never a single-stop edit — matching FLEET_STAFF_ROUTES_API.md's
 * own reasoning: partial stop edits invite sequence gaps and ordering bugs. Validation runs here,
 * across the whole set, because "are times increasing" and "are there at least two stops" are facts
 * about the set, not about any one stop.
 */
@Service
@BusinessRule({"BR-ROUTE-001", "BR-ROUTE-003", "BR-ROUTE-008"})
public class ReplaceStopsUseCase {

  private static final int MINIMUM_STOPS = 2;

  private final RouteRepository routeRepository;
  private final StopRepository stopRepository;
  private final AuditPort auditPort;

  public ReplaceStopsUseCase(
      RouteRepository routeRepository, StopRepository stopRepository, AuditPort auditPort) {
    this.routeRepository = routeRepository;
    this.stopRepository = stopRepository;
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

    // BR-ROUTE-008: strictly increasing times along the sequence, checked independently for
    // pickup and drop since a route runs in opposite directions morning and afternoon.
    assertIncreasing(ordered, StopInput::scheduledPickupTime);
    assertIncreasing(ordered, StopInput::scheduledDropTime);

    List<Stop> stops =
        ordered.stream()
            .map(
                input ->
                    new Stop(
                        StopId.generate(),
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
            .after(Map.of("stopCount", stops.size()))
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
