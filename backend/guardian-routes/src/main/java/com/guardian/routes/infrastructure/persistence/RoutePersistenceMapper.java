package com.guardian.routes.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.SchoolId;
import com.guardian.routes.domain.VehicleId;
import org.springframework.stereotype.Component;

/** Translates between the domain model and its JPA mapping. */
@Component
class RoutePersistenceMapper {

  Route toDomain(RouteEntity entity) {
    return new Route(
        RouteId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        SchoolId.of(entity.getSchoolId()),
        entity.getCode(),
        entity.getName(),
        entity.getDefaultVehicleId() == null ? null : VehicleId.of(entity.getDefaultVehicleId()),
        entity.isActive(),
        entity.getVersion());
  }

  RouteEntity toEntity(Route route) {
    return new RouteEntity(
        route.id().value(),
        route.tenantId().value(),
        route.schoolId().value(),
        route.code(),
        route.name(),
        route.defaultVehicleId().map(VehicleId::value).orElse(null),
        route.active(),
        route.version());
  }

  /**
   * Copies mutable state onto a managed entity, so Hibernate's dirty checking and {@code @Version}
   * apply. Persisting a freshly built detached entity would bypass optimistic locking and let a
   * concurrent edit silently win.
   */
  void applyTo(RouteEntity managed, Route route) {
    managed.applyMutableState(
        route.name(), route.defaultVehicleId().map(VehicleId::value).orElse(null), route.active());
  }
}
