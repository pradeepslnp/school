package com.guardian.routes.interfaces.rest.dto;

import com.guardian.routes.application.port.RouteStudentAssignmentRepository.StudentAssignment;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Wire types for student route assignment (feature RTE-003). See
 * guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md § Student Route Assignments.
 */
public final class StudentRouteAssignmentDtos {

  private StudentRouteAssignmentDtos() {}

  /**
   * {@code POST /routes/{routeId}/students}. The route comes from the path; the stop, student, and
   * direction from the body. {@code effectiveFrom} is optional — omitted, the assignment starts
   * today (the database's {@code valid_from} default).
   */
  public record AssignStudentRequest(
      @NotNull UUID studentId,
      @NotNull UUID stopId,
      @NotBlank @Pattern(regexp = "PICKUP|DROP") String direction,
      LocalDate effectiveFrom) {}

  /** One assignment as the enrolment screen reads it — the route and stop named, not just their
   * ids. */
  public record RouteAssignmentResponse(
      UUID id,
      UUID routeId,
      String routeCode,
      String routeName,
      UUID stopId,
      String stopName,
      UUID studentId,
      String direction,
      LocalDate validFrom) {

    public static RouteAssignmentResponse from(StudentAssignment assignment) {
      return new RouteAssignmentResponse(
          assignment.id(),
          assignment.routeId(),
          assignment.routeCode(),
          assignment.routeName(),
          assignment.stopId(),
          assignment.stopName(),
          assignment.studentId(),
          assignment.direction(),
          assignment.validFrom());
    }
  }
}
