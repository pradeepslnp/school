package com.guardian.trip.infrastructure.persistence;

import com.guardian.trip.application.port.TripManifestRepository;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code trip_manifests} (MOD-08).
 *
 * <p>The manifest is built in a single {@code INSERT ... SELECT} rather than by loading assignments
 * into Java and inserting them one by one. Not for speed — a route carries tens of children, not
 * thousands — but because the whole manifest then materialises inside one statement inside one
 * transaction. A partially-written manifest is a bus whose expected passenger list is shorter than
 * the children actually aboard, and trip-close reconciliation would report the difference as
 * children who should not have been there.
 *
 * <p>What the statement encodes, clause by clause:
 *
 * <ul>
 *   <li><strong>Active assignments for this trip's direction only.</strong> A child assigned a
 *       pickup stop but no drop stop belongs on the morning manifest and not the afternoon one.
 *   <li><strong>The assignment is valid on the service date</strong> — a child who joins the route
 *       next Monday is not on today's list, and one whose assignment ended on Friday is not either.
 *   <li><strong>The student is still enrolled.</strong> A withdrawn child is not expected on a bus.
 *   <li><strong>No active absence covers this date and run</strong> (BR-ABS-002). A null direction
 *       on an absence means both runs — the same convention the column carries.
 *   <li><strong>The name is snapshotted</strong>, not joined at read time (BR-AUD-003 in spirit):
 *       the manifest must still read correctly after a rename, a transfer, or a withdrawal.
 * </ul>
 *
 * <p>{@code ON CONFLICT DO NOTHING} on the (trip, student) unique key makes a repeated call a
 * no-op rather than an error, which keeps a retried start idempotent.
 */
@Component
public class JdbcTripManifestRepository implements TripManifestRepository {

  private final JdbcTemplate jdbc;

  public JdbcTripManifestRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public int materialiseFor(UUID tripId) {
    return jdbc.update(
        """
        INSERT INTO trip_manifests (tenant_id, trip_id, student_id, expected_stop_id,
                                    student_name_snapshot, sequence_no, status)
        SELECT t.tenant_id,
               t.id,
               rsa.student_id,
               rsa.stop_id,
               s.first_name || ' ' || s.last_name,
               st.sequence_no,
               'EXPECTED'
        FROM trips t
        JOIN route_student_assignments rsa
          ON rsa.route_id = t.route_id
         AND rsa.direction = t.direction
         AND rsa.is_active
         AND rsa.valid_from <= t.service_date
         AND (rsa.valid_to IS NULL OR rsa.valid_to >= t.service_date)
        JOIN stops st
          ON st.id = rsa.stop_id
         AND st.is_active
        JOIN students s
          ON s.id = rsa.student_id
         AND s.enrolment_status = 'ACTIVE'
        WHERE t.id = ?
          AND NOT EXISTS (
              SELECT 1
              FROM absences a
              WHERE a.student_id = rsa.student_id
                AND a.status = 'ACTIVE'
                AND a.from_date <= t.service_date
                AND a.to_date   >= t.service_date
                AND (a.direction IS NULL OR a.direction = t.direction)
          )
        ON CONFLICT (tenant_id, trip_id, student_id) DO NOTHING
        """,
        tripId);
  }

  @Override
  public int countFor(UUID tripId) {
    Integer count =
        jdbc.queryForObject(
            "SELECT count(*) FROM trip_manifests WHERE trip_id = ?", Integer.class, tripId);
    return count == null ? 0 : count;
  }
}
