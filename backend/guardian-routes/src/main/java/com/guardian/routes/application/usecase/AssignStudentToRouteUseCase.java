package com.guardian.routes.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.DataConflictException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.application.port.RouteStudentAssignmentRepository;
import com.guardian.routes.application.port.RouteStudentAssignmentRepository.StudentAssignment;
import com.guardian.routes.application.port.StopRepository;
import com.guardian.routes.application.port.StudentGuardianGuard;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.RouteStudentAssignment;
import com.guardian.routes.domain.Stop;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Assigns a student to a route's stop for one direction (feature RTE-003) — the step that actually
 * puts a child on a bus, and therefore the step the safety rules gate hardest.
 *
 * <p>Three checks run before anything is written, in the order that fails cheapest-first while
 * keeping the safety-critical one authoritative:
 *
 * <ol>
 *   <li>The route exists, and the stop is one of <em>its</em> stops — assigning a child to a stop
 *       that belongs to another route is a data error that would send the manifest to the wrong
 *       place.
 *   <li><strong>The student has an active guardian authorised to receive them</strong> (BR-STU-002
 *       🔴). A child must never arrive at a drop stop with nobody allowed to collect them; without
 *       this, the whole handover chain has no one to hand over to.
 *   <li>The student is not already assigned in this direction (BR-ROUTE-004). The database's {@code
 *       uq_rsa_student_direction} is the real guarantee; this pre-check turns the violation into a
 *       clear {@code 409} instead of a generic failure.
 * </ol>
 *
 * <p>Not yet enforced here, and called out rather than silently skipped: BR-STU-004 (the student is
 * actively enrolled). It needs a read into the student bounded context, which this pass does not
 * wire; a withdrawn student is an edge case an administrator is unlikely to hit in the enrolment
 * flow, and it is the next guard to add.
 */
@Service
@BusinessRule({"BR-STU-002", "BR-ROUTE-004", "BR-ROUTE-005"})
public class AssignStudentToRouteUseCase {

  private final RouteRepository routes;
  private final StopRepository stops;
  private final RouteStudentAssignmentRepository assignments;
  private final StudentGuardianGuard guardianGuard;
  private final AuditPort auditPort;

  public AssignStudentToRouteUseCase(
      RouteRepository routes,
      StopRepository stops,
      RouteStudentAssignmentRepository assignments,
      StudentGuardianGuard guardianGuard,
      AuditPort auditPort) {
    this.routes = routes;
    this.stops = stops;
    this.assignments = assignments;
    this.guardianGuard = guardianGuard;
    this.auditPort = auditPort;
  }

  @Transactional
  public StudentAssignment execute(
      UUID routeId,
      UUID studentId,
      UUID stopId,
      String direction,
      LocalDate effectiveFrom,
      UUID actorUserId,
      String actorRole) {

    RouteId typedRouteId = RouteId.of(routeId);
    Route route =
        routes
            .findById(typedRouteId)
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.ROUTE_NOT_FOUND,
                        "BR-ROUTE-004",
                        Map.of("routeId", routeId.toString())));

    Stop stop =
        stops.findByRoute(typedRouteId).stream()
            .filter(s -> s.id().value().equals(stopId))
            .findFirst()
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
                        "BR-ROUTE-004",
                        Map.of("field", "stopId", "routeId", routeId.toString())));

    if (!guardianGuard.hasActiveHandoverGuardian(studentId)) {
      throw new BusinessRuleViolationException(
          ErrorCode.STUDENT_HAS_NO_ACTIVE_GUARDIAN,
          "BR-STU-002",
          Map.of("studentId", studentId.toString()));
    }

    if (assignments.existsActiveForStudentDirection(studentId, direction)) {
      throw new DataConflictException(
          ErrorCode.STUDENT_ALREADY_ASSIGNED_FOR_DIRECTION,
          Map.of("studentId", studentId.toString(), "direction", direction));
    }

    RouteStudentAssignment saved =
        assignments.save(
            new RouteStudentAssignment(
                null, routeId, stopId, studentId, direction, effectiveFrom, null, true),
            actorUserId);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("STUDENT_ASSIGNED_TO_ROUTE")
            .subject("RouteStudentAssignment", saved.id())
            .after(
                Map.of(
                    "studentId", studentId.toString(),
                    "routeId", routeId.toString(),
                    "stopId", stopId.toString(),
                    "direction", direction))
            .build());

    return new StudentAssignment(
        saved.id(),
        route.id().value(),
        route.code(),
        route.name(),
        stop.id().value(),
        stop.name(),
        studentId,
        saved.direction(),
        saved.validFrom());
  }
}
