package com.guardian.routes.application.usecase;

import com.guardian.routes.application.port.RouteStudentAssignmentRepository;
import com.guardian.routes.application.port.RouteStudentAssignmentRepository.StudentAssignment;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A student's active route assignments — their pickup and drop, each with the route and stop it
 * names (feature RTE-003), for the enrolment screen.
 *
 * <p>Read-only and tenant-scoped by row-level security.
 */
@Service
public class ListStudentRouteAssignmentsUseCase {

  private final RouteStudentAssignmentRepository assignments;

  public ListStudentRouteAssignmentsUseCase(RouteStudentAssignmentRepository assignments) {
    this.assignments = assignments;
  }

  @Transactional(readOnly = true)
  public List<StudentAssignment> execute(UUID studentId) {
    return assignments.findActiveForStudent(studentId);
  }
}
