package com.guardian.routes.infrastructure.persistence;

import com.guardian.routes.application.port.RouteStudentAssignmentRepository;
import com.guardian.routes.domain.RouteStudentAssignment;
import java.sql.Date;
import java.sql.ResultSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code route_student_assignments} (MOD-07) — matching {@code
 * StopJdbcRepository}'s plain-JDBC style in this module rather than JPA.
 *
 * <p>Runs under row-level security, so tenant scoping is absent from the SQL by design; the {@code
 * tenant_id} written on insert comes from the session setting the RLS policy itself reads.
 */
@Component
public class JdbcRouteStudentAssignmentRepository implements RouteStudentAssignmentRepository {

  private final JdbcTemplate jdbc;

  public JdbcRouteStudentAssignmentRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public boolean existsActiveForStudentDirection(UUID studentId, String direction) {
    Boolean exists =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1 FROM route_student_assignments
                WHERE student_id = ? AND direction = ? AND is_active)
            """,
            Boolean.class,
            studentId,
            direction);
    return Boolean.TRUE.equals(exists);
  }

  @Override
  public RouteStudentAssignment save(RouteStudentAssignment assignment, UUID actorUserId) {
    // valid_from is NOT NULL DEFAULT CURRENT_DATE; COALESCE lets a null effectiveFrom fall to the
    // database default rather than violating the constraint. id and the stored valid_from are read
    // back in the same statement so the returned object carries exactly what the row holds.
    Map<String, Object> row =
        jdbc.queryForMap(
            """
            INSERT INTO route_student_assignments
                   (tenant_id, route_id, stop_id, student_id, direction,
                    valid_from, valid_to, is_active, created_by, updated_by)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, COALESCE(?, CURRENT_DATE), NULL, true, ?, ?)
            RETURNING id, valid_from
            """,
            assignment.routeId(),
            assignment.stopId(),
            assignment.studentId(),
            assignment.direction(),
            assignment.validFrom() == null ? null : Date.valueOf(assignment.validFrom()),
            actorUserId,
            actorUserId);

    UUID id = (UUID) row.get("id");
    Date validFrom = (Date) row.get("valid_from");

    return new RouteStudentAssignment(
        id,
        assignment.routeId(),
        assignment.stopId(),
        assignment.studentId(),
        assignment.direction(),
        validFrom == null ? null : validFrom.toLocalDate(),
        null,
        true);
  }

  @Override
  public List<StudentAssignment> findActiveForStudent(UUID studentId) {
    return jdbc.query(
        """
        SELECT rsa.id, rsa.route_id, r.code AS route_code, r.name AS route_name,
               rsa.stop_id, s.name AS stop_name, rsa.student_id, rsa.direction, rsa.valid_from
        FROM route_student_assignments rsa
        JOIN routes r ON r.id = rsa.route_id
        JOIN stops  s ON s.id = rsa.stop_id
        WHERE rsa.student_id = ? AND rsa.is_active
        ORDER BY rsa.direction
        """,
        ASSIGNMENT_MAPPER,
        studentId);
  }

  @Override
  public void deactivate(UUID assignmentId, UUID actorUserId) {
    jdbc.update(
        """
        UPDATE route_student_assignments
           SET is_active = false, valid_to = CURRENT_DATE,
               updated_at = now(), updated_by = ?, version = version + 1
         WHERE id = ? AND is_active
        """,
        actorUserId,
        assignmentId);
  }

  private static final RowMapper<StudentAssignment> ASSIGNMENT_MAPPER =
      (ResultSet rs, int rowNum) -> {
        Date validFrom = rs.getDate("valid_from");
        return new StudentAssignment(
            rs.getObject("id", UUID.class),
            rs.getObject("route_id", UUID.class),
            rs.getString("route_code"),
            rs.getString("route_name"),
            rs.getObject("stop_id", UUID.class),
            rs.getString("stop_name"),
            rs.getObject("student_id", UUID.class),
            rs.getString("direction"),
            validFrom == null ? null : validFrom.toLocalDate());
      };
}
