package com.guardian.infrastructure.student;

import com.guardian.guardian.application.port.GuardianRepository;
import com.guardian.routes.application.port.RouteStudentAssignmentRepository;
import com.guardian.student.application.port.StudentSetupRowsPort;
import com.guardian.student.domain.StudentId;
import org.springframework.stereotype.Component;

/**
 * Implements guardian-student's {@link StudentSetupRowsPort} with the guardian and routes modules'
 * own repositories — the composition root is the one place allowed to see all three, which is why
 * the port lives in guardian-student and this adapter lives here (ADR-0019). Same shape as {@code
 * StudentGuardianGuardAdapter}.
 *
 * <p>Calls the repositories directly rather than through use cases: the discard already holds the
 * transaction and tenant context, and writes the one audit record, with these counts, itself.
 */
@Component
class StudentSetupRowsAdapter implements StudentSetupRowsPort {

  private final GuardianRepository guardians;
  private final RouteStudentAssignmentRepository routeAssignments;

  StudentSetupRowsAdapter(
      GuardianRepository guardians, RouteStudentAssignmentRepository routeAssignments) {
    this.guardians = guardians;
    this.routeAssignments = routeAssignments;
  }

  @Override
  public int deleteGuardianLinks(StudentId studentId) {
    return guardians.deleteLinksForStudent(studentId.value());
  }

  @Override
  public int deleteRouteAssignments(StudentId studentId) {
    return routeAssignments.deleteAllForStudent(studentId.value());
  }
}
