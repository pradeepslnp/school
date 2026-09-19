package com.guardian.parent.infrastructure.persistence;

import com.guardian.common.security.AccessScope;
import com.guardian.parent.application.port.StudentTransportReadModel;
import com.guardian.parent.application.result.StudentTransportView;
import com.guardian.parent.application.result.StudentTransportView.CrewMember;
import com.guardian.parent.application.result.StudentTransportView.Leg;
import com.guardian.parent.application.result.StudentTransportView.Vehicle;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * The staff-facing transport projection (feature STU-009, ADR-0020) — the whole of its cross-module
 * coupling, in one file, alongside {@link JdbcParentReadModel}.
 *
 * <p>It reads tables owned by MOD-03 (students), MOD-01 (schools, for the timezone), MOD-07 (route
 * assignments, routes, stops), MOD-05 (vehicles) and MOD-06 (duty assignments, transport staff).
 * Read-only; row-level security applies to every statement.
 *
 * <p><strong>Two properties are load-bearing.</strong>
 *
 * <ul>
 *   <li><em>Scope lives in the WHERE clause</em> of the first query ({@code school_id = ANY(?)},
 *       unless the caller is organization-wide). A student outside it returns nothing, and the
 *       later queries never run (BR-IAM-006).
 *   <li><em>"Today" is the school's day</em>, not the server's (BR-CFG-006): a duty that starts
 *       tomorrow is not today's crew, and the server runs in UTC.
 * </ul>
 *
 * <p>An assignment counts when it is active — the same predicate the student record's pickup and
 * drop panel uses ({@code JdbcRouteStudentAssignmentRepository.findActiveForStudent}), so the two
 * panels can never disagree about which route a child is on. A duty counts when it is active, for
 * this direction or both, and in effect today.
 */
@Component
public class JdbcStudentTransportReadModel implements StudentTransportReadModel {

  private static final String STUDENT_SQL =
      """
      SELECT st.school_id, (now() AT TIME ZONE sch.timezone)::date AS school_today
      FROM students st
      JOIN schools sch ON sch.id = st.school_id
      WHERE st.id = ? AND (? OR st.school_id = ANY (?))
      """;

  private static final String LEGS_SQL =
      """
      SELECT rsa.direction, r.id AS route_id, r.code AS route_code, r.name AS route_name,
             sp.id AS stop_id, sp.name AS stop_name,
             v.id AS vehicle_id, v.registration_no, v.display_name, v.status AS vehicle_status
      FROM route_student_assignments rsa
      JOIN routes r  ON r.id = rsa.route_id
      JOIN stops  sp ON sp.id = rsa.stop_id
      LEFT JOIN vehicles v ON v.id = r.default_vehicle_id
      WHERE rsa.student_id = ? AND rsa.is_active
      ORDER BY CASE rsa.direction WHEN 'PICKUP' THEN 0 ELSE 1 END
      """;

  private static final String CREW_SQL =
      """
      SELECT rsa.direction AS leg_direction, da.role, ts.id AS staff_id,
             ts.first_name, ts.last_name
      FROM route_student_assignments rsa
      JOIN duty_assignments da
        ON da.route_id = rsa.route_id
       AND da.is_active
       AND (da.direction IS NULL OR da.direction = rsa.direction)
       AND da.effective_from <= ?
       AND (da.effective_until IS NULL OR da.effective_until >= ?)
      JOIN transport_staff ts ON ts.id = da.staff_id AND ts.is_active
      WHERE rsa.student_id = ? AND rsa.is_active
      ORDER BY CASE da.role WHEN 'DRIVER' THEN 0 ELSE 1 END, ts.first_name, ts.last_name
      """;

  private final JdbcTemplate jdbc;

  public JdbcStudentTransportReadModel(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public Optional<StudentTransportView> transportOf(UUID studentId, AccessScope scope) {
    List<StudentRow> students =
        jdbc.query(
            connection -> {
              var statement = connection.prepareStatement(STUDENT_SQL);
              statement.setObject(1, studentId);
              statement.setBoolean(2, scope.organizationWide());
              statement.setArray(3, connection.createArrayOf("uuid", scope.schoolIds().toArray()));
              return statement;
            },
            (rs, rowNum) ->
                new StudentRow(
                    rs.getObject("school_id", UUID.class),
                    rs.getDate("school_today").toLocalDate()));
    if (students.isEmpty()) {
      return Optional.empty();
    }
    StudentRow student = students.get(0);

    Map<String, List<CrewMember>> crewByDirection = new LinkedHashMap<>();
    jdbc.query(
        CREW_SQL,
        rs -> {
          crewByDirection
              .computeIfAbsent(rs.getString("leg_direction"), direction -> new ArrayList<>())
              .add(
                  new CrewMember(
                      rs.getObject("staff_id", UUID.class),
                      rs.getString("role"),
                      rs.getString("first_name"),
                      rs.getString("last_name")));
        },
        Date.valueOf(student.today()),
        Date.valueOf(student.today()),
        studentId);

    List<Leg> legs =
        jdbc.query(
            LEGS_SQL,
            (rs, rowNum) -> {
              UUID vehicleId = rs.getObject("vehicle_id", UUID.class);
              String direction = rs.getString("direction");
              return new Leg(
                  direction,
                  rs.getObject("route_id", UUID.class),
                  rs.getString("route_code"),
                  rs.getString("route_name"),
                  rs.getObject("stop_id", UUID.class),
                  rs.getString("stop_name"),
                  vehicleId == null
                      ? null
                      : new Vehicle(
                          vehicleId,
                          rs.getString("registration_no"),
                          rs.getString("display_name"),
                          rs.getString("vehicle_status")),
                  crewByDirection.getOrDefault(direction, List.of()));
            },
            studentId);

    return Optional.of(new StudentTransportView(studentId, student.schoolId(), legs));
  }

  private record StudentRow(UUID schoolId, LocalDate today) {}
}
