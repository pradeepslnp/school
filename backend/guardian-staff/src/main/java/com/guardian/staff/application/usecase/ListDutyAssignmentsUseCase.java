package com.guardian.staff.application.usecase;

import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.application.result.RouteCrewMember;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.TransportStaff;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;

/**
 * Lists a route's standing crew, each with the name of the person holding the duty (feature
 * STF-004, screen A-25).
 *
 * <p>The name is resolved here rather than left to the caller: a roster of ids cannot be read, and
 * a client joining it would be a client deciding which staff record a duty belongs to. A route
 * carries a handful of crew, so this is a lookup per row rather than a join — both tables are this
 * module's own, and the set is bounded by what one bus can carry as crew.
 *
 * <p>A duty whose staff record has since been removed keeps its row with an empty name, rather than
 * disappearing: an operator must see that the route has a crew slot nobody fills.
 */
@Service
public class ListDutyAssignmentsUseCase {

  private final DutyAssignmentRepository dutyAssignmentRepository;
  private final TransportStaffRepository staffRepository;

  public ListDutyAssignmentsUseCase(
      DutyAssignmentRepository dutyAssignmentRepository, TransportStaffRepository staffRepository) {
    this.dutyAssignmentRepository = dutyAssignmentRepository;
    this.staffRepository = staffRepository;
  }

  public List<RouteCrewMember> forRoute(RouteId routeId) {
    return dutyAssignmentRepository.findByRoute(routeId).stream().map(this::withStaff).toList();
  }

  private RouteCrewMember withStaff(DutyAssignment assignment) {
    Optional<TransportStaff> staff = staffRepository.findById(assignment.staffId());
    return new RouteCrewMember(
        assignment.id(),
        assignment.staffId(),
        assignment.routeId(),
        staff.map(TransportStaff::firstName).orElse(""),
        staff.map(TransportStaff::lastName).orElse(""),
        assignment.role(),
        assignment.direction().map(Enum::name),
        assignment.effectiveFrom(),
        assignment.effectiveUntil(),
        assignment.active());
  }
}
