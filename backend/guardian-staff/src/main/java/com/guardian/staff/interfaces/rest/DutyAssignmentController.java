package com.guardian.staff.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.staff.application.command.AssignDutyCommand;
import com.guardian.staff.application.usecase.AssignDutyUseCase;
import com.guardian.staff.application.usecase.ListDutyAssignmentsUseCase;
import com.guardian.staff.application.usecase.RemoveDutyAssignmentUseCase;
import com.guardian.staff.application.usecase.ReplaceDutyAssignmentUseCase;
import com.guardian.staff.domain.Direction;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.DutyAssignmentId;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.interfaces.rest.dto.AssignDutyRequest;
import com.guardian.staff.interfaces.rest.dto.DutyAssignmentResponse;
import com.guardian.staff.interfaces.rest.dto.ReplaceDutyRequest;
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
 * Duty assignment endpoints (feature STF-004). See guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md
 * §Duty Assignments.
 *
 * <p>Every method declares a permission from the permission matrix — an architecture test fails the
 * build for any endpoint that does not (BR-IAM-002). This layer only translates: parse the wire
 * format into domain types, call one use case, map the result back.
 */
@RestController
public class DutyAssignmentController {

  private final AssignDutyUseCase assignDuty;
  private final ListDutyAssignmentsUseCase listDutyAssignments;
  private final RemoveDutyAssignmentUseCase removeDutyAssignment;
  private final ReplaceDutyAssignmentUseCase replaceDutyAssignment;

  public DutyAssignmentController(
      AssignDutyUseCase assignDuty,
      ListDutyAssignmentsUseCase listDutyAssignments,
      RemoveDutyAssignmentUseCase removeDutyAssignment,
      ReplaceDutyAssignmentUseCase replaceDutyAssignment) {
    this.assignDuty = assignDuty;
    this.listDutyAssignments = listDutyAssignments;
    this.removeDutyAssignment = removeDutyAssignment;
    this.replaceDutyAssignment = replaceDutyAssignment;
  }

  @PostMapping("/api/v1/routes/{routeId}/duty-assignments")
  @RequiresPermission("PERM-DUTY-ASSIGN")
  public ResponseEntity<DutyAssignmentResponse> assign(
      @PathVariable UUID routeId,
      @Valid @RequestBody AssignDutyRequest request,
      CurrentActor actor) {

    AssignDutyCommand command =
        new AssignDutyCommand(
            RouteId.of(routeId),
            StaffId.of(request.staffId()),
            StaffType.valueOf(request.role()),
            request.direction() == null ? null : Direction.valueOf(request.direction()),
            actor.userId(),
            actor.role());

    DutyAssignment created = assignDuty.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/duty-assignments/" + created.id()))
        .body(DutyAssignmentResponse.from(created));
  }

  @GetMapping("/api/v1/routes/{routeId}/duty-assignments")
  @RequiresPermission("PERM-ROUTE-VIEW")
  public List<DutyAssignmentResponse> listForRoute(@PathVariable UUID routeId) {
    return listDutyAssignments.forRoute(RouteId.of(routeId)).stream()
        .map(DutyAssignmentResponse::from)
        .toList();
  }

  /**
   * Puts a different driver or attendant on this duty (feature STF-004) — the standing roster, not
   * a substitute for one trip (BR-STAFF-006, STF-005). Old off and new on in one transaction,
   * audited with both people and the reason.
   */
  @PostMapping("/api/v1/duty-assignments/{id}/replace")
  @RequiresPermission("PERM-DUTY-ASSIGN")
  public DutyAssignmentResponse replace(
      @PathVariable UUID id, @Valid @RequestBody ReplaceDutyRequest request, CurrentActor actor) {

    return DutyAssignmentResponse.from(
        replaceDutyAssignment.execute(
            DutyAssignmentId.of(id),
            StaffId.of(request.staffId()),
            request.reason(),
            actor.userId(),
            actor.role()));
  }

  @DeleteMapping("/api/v1/duty-assignments/{id}")
  @RequiresPermission("PERM-DUTY-ASSIGN")
  public ResponseEntity<Void> remove(@PathVariable UUID id, CurrentActor actor) {
    removeDutyAssignment.execute(DutyAssignmentId.of(id), actor.userId(), actor.role());
    return ResponseEntity.noContent().build();
  }
}
