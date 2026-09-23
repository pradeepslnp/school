package com.guardian.routes.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.routes.application.command.CreateRouteCommand;
import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.domain.Route;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Creates a route (feature RTE-001).
 *
 * <p>The route is usable for student assignment only once it has at least two stops (BR-ROUTE-001)
 * — that happens through a separate call to {@code ReplaceStopsUseCase}, matching how {@code PUT
 * /routes/{id}/stops} is documented as its own step in FLEET_STAFF_ROUTES_API.md. Splitting
 * creation from stop entry means a route with no stops yet can still be saved as a draft rather
 * than forcing the whole shape to be submitted in one request.
 */
@Service
@BusinessRule({"BR-ROUTE-001", "BR-AUD-002"})
public class CreateRouteUseCase {

  private final RouteRepository routeRepository;
  private final AuditPort auditPort;

  public CreateRouteUseCase(RouteRepository routeRepository, AuditPort auditPort) {
    this.routeRepository = routeRepository;
    this.auditPort = auditPort;
  }

  /**
   * @throws BusinessRuleViolationException if the code is already used within the school
   *     (BR-ROUTE-001)
   */
  @Transactional
  public Route execute(CreateRouteCommand command) {
    TenantId tenantId = TenantContext.require();

    if (routeRepository.existsByCode(command.schoolId(), command.code())) {
      throw new BusinessRuleViolationException(
          ErrorCode.ROUTE_CODE_ALREADY_EXISTS, "BR-ROUTE-001", Map.of("code", command.code()));
    }

    Route route =
        Route.create(
            tenantId,
            command.schoolId(),
            command.code(),
            command.name(),
            command.defaultVehicleId(),
            command.operatingDays());

    Route saved = routeRepository.save(route);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ROUTE_CREATED")
            .subject("Route", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(Route route) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("code", route.code());
    values.put("name", route.name());
    values.put("defaultVehicleId", route.defaultVehicleId().map(Object::toString).orElse(null));
    values.put("operatingDays", route.operatingDays().toStoredValue());
    return values;
  }
}
