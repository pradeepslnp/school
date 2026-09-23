package com.guardian.routes.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.routes.application.command.UpdateRouteCommand;
import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.domain.Route;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Edits a route's name, default vehicle, operating days, or active flag (feature RTE-001).
 *
 * <p>This use case exists because V22 gave routes an {@code operating_days} column that decides
 * whether MOD-08 generates a trip at all, and a field that controls whether buses run is not one to
 * leave editable by nobody. There was no route update path before it.
 *
 * <p>The audit record carries both before and after values. "Who stopped the Saturday service?" is
 * a question somebody asks on a Saturday morning, and a record showing only the new value cannot
 * answer it.
 *
 * <p>Deliberately not editable here: the route's {@code code}, its school, and its active flag.
 * Deactivation is conditional on releasing every student assigned to the route (BR-ROUTE-007), a
 * check that is not built; offering the flag without it would strand children on a route that
 * stops generating trips. A code appears on
 * printed lists, in messages to parents and on every trip generated under it, so changing one
 * re-labels history that has already been acted on; retiring the route and creating its replacement
 * keeps that history true. Moving a route between schools would orphan its stops, its student
 * assignments and its duty roster in one statement.
 */
@Service
@BusinessRule({"BR-ROUTE-001", "BR-AUD-002"})
public class UpdateRouteUseCase {

  private final RouteRepository routeRepository;
  private final AuditPort auditPort;

  public UpdateRouteUseCase(RouteRepository routeRepository, AuditPort auditPort) {
    this.routeRepository = routeRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public Route execute(UpdateRouteCommand command) {
    Route existing =
        routeRepository
            .findById(command.routeId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.ROUTE_NOT_FOUND, "Route", command.routeId().value()));

    Route edited =
        existing.withEdits(
            command.name(), command.defaultVehicleId(), command.operatingDays());

    Route saved = routeRepository.save(edited);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ROUTE_UPDATED")
            .subject("Route", saved.id().value())
            .before(describe(existing))
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(Route route) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("name", route.name());
    values.put("defaultVehicleId", route.defaultVehicleId().map(Object::toString).orElse(null));
    values.put("operatingDays", route.operatingDays().toStoredValue());
    return values;
  }
}
