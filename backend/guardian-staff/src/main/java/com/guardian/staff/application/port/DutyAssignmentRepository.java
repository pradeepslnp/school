package com.guardian.staff.application.port;

import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.DutyAssignmentId;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.StaffId;
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

  /**
   * Every currently-active standing assignment for one staff member — what deactivating them must
   * clear (BR-IAM-008). The standing roster only, not any in-progress trip's crew (that is MOD-08's
   * {@code trip_staff}, and a trip already under way keeps the person who started it).
   */
  List<DutyAssignment> findActiveByStaff(StaffId staffId);

  DutyAssignment save(DutyAssignment assignment);

  /**
   * Deletes every assignment, active or not, held by a staff record being discarded (BR-STAFF-007).
   * Never used to end an assignment — that is {@link DutyAssignment#deactivate()}.
   *
   * @return how many were removed
   */
  int deleteAllForStaff(StaffId staffId);
}
