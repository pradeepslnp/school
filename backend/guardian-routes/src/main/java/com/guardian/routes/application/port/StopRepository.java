package com.guardian.routes.application.port;

import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.Stop;
import java.util.List;

/**
 * Persistence for a route's {@link Stop} list.
 *
 * <p>Stops are always written as a full ordered replacement, never a single-row edit — matching
 * {@code PUT /routes/{id}/stops}'s own contract (FLEET_STAFF_ROUTES_API.md): partial stop edits
 * invite sequence gaps and ordering bugs.
 */
public interface StopRepository {

  List<Stop> findByRoute(RouteId routeId);

  void replaceAll(RouteId routeId, List<Stop> stops);
}
