package com.guardian.routes.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.routes.application.port.RouteStudentAssignmentRepository.StudentAssignment;
import com.guardian.routes.application.usecase.AssignStudentToRouteUseCase;
import com.guardian.routes.application.usecase.ListStudentRouteAssignmentsUseCase;
import com.guardian.routes.application.usecase.RemoveStudentAssignmentUseCase;
import com.guardian.routes.interfaces.rest.dto.StudentRouteAssignmentDtos.AssignStudentRequest;
import com.guardian.routes.interfaces.rest.dto.StudentRouteAssignmentDtos.RouteAssignmentResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Student route assignment (feature RTE-003). See guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md §
 * Student Route Assignments.
 *
 * <p>Three paths on three resources rather than one nested block, so no class-level mapping: a
 * student is assigned <em>to a route</em> ({@code POST /routes/{routeId}/students}), read <em>from
 * the student</em> ({@code GET /students/{studentId}/route-assignments}, matching how the enrolment
 * screen thinks), and removed <em>by the assignment's own id</em> ({@code DELETE
 * /route-assignments/{id}}) — a student may hold pickup on one route and drop on another, so the
 * assignment is its own addressable thing.
 *
 * <p>Writing declares {@code PERM-ROUTE-ASSIGN-STUDENT}; reading declares {@code PERM-STUDENT-VIEW}
 * — an architecture test fails the build for any endpoint that declares neither.
 */
@RestController
public class StudentRouteAssignmentController {

  private final AssignStudentToRouteUseCase assignStudent;
  private final ListStudentRouteAssignmentsUseCase listAssignments;
  private final RemoveStudentAssignmentUseCase removeAssignment;

  public StudentRouteAssignmentController(
      AssignStudentToRouteUseCase assignStudent,
      ListStudentRouteAssignmentsUseCase listAssignments,
      RemoveStudentAssignmentUseCase removeAssignment) {
    this.assignStudent = assignStudent;
    this.listAssignments = listAssignments;
    this.removeAssignment = removeAssignment;
  }

  @PostMapping("/api/v1/routes/{routeId}/students")
  @RequiresPermission("PERM-ROUTE-ASSIGN-STUDENT")
  public ResponseEntity<RouteAssignmentResponse> assign(
      @PathVariable UUID routeId,
      @Valid @RequestBody AssignStudentRequest request,
      CurrentActor actor) {

    StudentAssignment saved =
        assignStudent.execute(
            routeId,
            request.studentId(),
            request.stopId(),
            request.direction(),
            request.effectiveFrom(),
            actor.userId(),
            actor.role());

    return ResponseEntity.created(URI.create("/api/v1/route-assignments/" + saved.id()))
        .body(RouteAssignmentResponse.from(saved));
  }

  @GetMapping("/api/v1/students/{studentId}/route-assignments")
  @RequiresPermission("PERM-STUDENT-VIEW")
  public List<RouteAssignmentResponse> list(@PathVariable UUID studentId) {
    return listAssignments.execute(studentId).stream().map(RouteAssignmentResponse::from).toList();
  }

  @DeleteMapping("/api/v1/route-assignments/{assignmentId}")
  @RequiresPermission("PERM-ROUTE-ASSIGN-STUDENT")
  public ResponseEntity<Void> remove(@PathVariable UUID assignmentId, CurrentActor actor) {
    removeAssignment.execute(assignmentId, actor.userId(), actor.role());
    return ResponseEntity.noContent().build();
  }
}
