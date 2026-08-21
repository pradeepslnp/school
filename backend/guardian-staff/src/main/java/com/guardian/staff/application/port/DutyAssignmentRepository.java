package com.guardian.staff.application.port;

import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.DutyAssignmentId;
import com.guardian.staff.domain.RouteId;
import java.util.List;
import java.util.Optional;

/**
 * Persistence for {@link DutyAssignment}, defined in the domain's language.
 *
 * <p>Every method here is implicitly tenant-scoped: row-level security applies the {@code
 * tenant_id} predicate to every query (ADR-0001).
 */
public interface DutyAssignmentRepository {

  Optional<DutyAssignment> findById(DutyAssignmentId id);

  List<DutyAssignment> findByRoute(RouteId routeId);

  DutyAssignment save(DutyAssignment assignment);
}
