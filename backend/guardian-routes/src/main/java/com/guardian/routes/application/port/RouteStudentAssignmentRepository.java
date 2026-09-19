package com.guardian.routes.application.port;

import com.guardian.routes.domain.RouteStudentAssignment;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Persistence for {@link RouteStudentAssignment} (MOD-07).
 *
 * <p>Every method is implicitly tenant-scoped by row-level security (ADR-0001), so no method takes
 * a tenant argument.
 */
public interface RouteStudentAssignmentRepository {

  /**
   * Whether the student already holds an active assignment in this direction — BR-ROUTE-004 as a
   * pre-flight check, so a second pickup is refused with a clear {@code
   * STUDENT_ALREADY_ASSIGNED_FOR_DIRECTION} rather than surfacing the {@code
   * uq_rsa_student_direction} violation as a generic failure. The unique index remains the actual
   * guarantee; this only narrows the race window and gives a better message.
   */
  boolean existsActiveForStudentDirection(UUID studentId, String direction);

  RouteStudentAssignment save(RouteStudentAssignment assignment, UUID actorUserId);

  /**
   * A student's active assignments, joined with the route and stop they name, for the enrolment
   * screen (RTE-003).
   */
  List<StudentAssignment> findActiveForStudent(UUID studentId);

  /**
   * Deactivates an assignment. Never a delete — a past manifest must still show who was expected.
   */
  void deactivate(UUID assignmentId, UUID actorUserId);

  /**
   * Deletes every assignment, active or not, held by a student being discarded as a mistaken entry
   * (BR-STU-007, ADR-0019). The one exception to "never a delete": a student who was never really
   * enrolled can appear on no manifest, and {@code trip_manifests} refuses the student's own delete
   * if they somehow did.
   *
   * @return how many were removed
   */
  int deleteAllForStudent(UUID studentId);

  /**
   * Which of {@code stopIds} still have a student actively assigned to them — a stop in this set
   * cannot be removed from its route until those students are moved (BR-ROUTE-009).
   */
  List<UUID> stopsWithActiveAssignments(Collection<UUID> stopIds);

  /**
   * A student's assignment as the enrolment screen reads it: the assignment joined with the route
   * and stop it points at, so the screen shows "Route R3 · Green Park" rather than two opaque ids.
   * A read projection spanning three tables, never written back through.
   */
  record StudentAssignment(
      UUID id,
      UUID routeId,
      String routeCode,
      String routeName,
      UUID stopId,
      String stopName,
      UUID studentId,
      String direction,
      LocalDate validFrom) {}
}
