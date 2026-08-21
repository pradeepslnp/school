package com.guardian.routes.application.port;

import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.SchoolId;
import java.util.List;
import java.util.Optional;

/**
 * Persistence for {@link Route}, defined in the domain's language.
 *
 * <p>Every method here is implicitly tenant-scoped: row-level security applies the {@code
 * tenant_id} predicate to every query (ADR-0001). No method takes a tenant argument.
 */
public interface RouteRepository {

  Optional<Route> findById(RouteId id);

  List<Route> findBySchool(SchoolId schoolId);

  boolean existsByCode(SchoolId schoolId, String code);

  Route save(Route route);
}
