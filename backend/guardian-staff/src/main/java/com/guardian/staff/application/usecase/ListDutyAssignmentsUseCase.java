package com.guardian.staff.application.usecase;

import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.RouteId;
import java.util.List;
import org.springframework.stereotype.Service;

/** Lists a route's standing crew (feature STF-004). */
@Service
public class ListDutyAssignmentsUseCase {

  private final DutyAssignmentRepository dutyAssignmentRepository;

  public ListDutyAssignmentsUseCase(DutyAssignmentRepository dutyAssignmentRepository) {
    this.dutyAssignmentRepository = dutyAssignmentRepository;
  }

  public List<DutyAssignment> forRoute(RouteId routeId) {
    return dutyAssignmentRepository.findByRoute(routeId);
  }
}
