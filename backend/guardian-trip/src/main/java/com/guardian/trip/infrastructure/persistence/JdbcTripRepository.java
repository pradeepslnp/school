package com.guardian.trip.infrastructure.persistence;

import com.guardian.trip.application.port.CrewTrip;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.ScheduledRun;
import com.guardian.trip.domain.Trip;
import com.guardian.trip.domain.TripDirection;
import com.guardian.trip.domain.TripStatus;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code trips} (MOD-08).
 *
 * <p>Two things in here carry more weight than their line count suggests:
 *
 * <ul>
 *   <li><strong>Generation is one statement with {@code ON CONFLICT DO NOTHING}.</strong> The
 *       unique key on (tenant, route, service date, direction) is what makes trip generation safe
 *       to run twice, from two places, at the same moment — which is what lets the nightly job, a
 *       manual re-run and a second application instance coexist without a distributed lock.
 *   <li><strong>Every status change is a guarded UPDATE.</strong> The expected current status is in
 *       the {@code WHERE} clause, so two crew members tapping "start" produce one start and one
 *       refusal. Checking the status in Java and then updating would leave a window between them
 *       wide enough for exactly the double-start that puts one bus on two manifests.
 * </ul>
 *
 * <p>No statement mentions {@code tenant_id}: row-level security scopes them all, and repeating the
 * predicate would suggest the policy were optional.
 */
@Component
public class JdbcTripRepository implements TripRepository {

  private static final String SELECT_COLUMNS =
      """
      SELECT id, school_id, route_id, vehicle_id, service_date, direction, status,
             scheduled_start_time, started_at, ended_at, closed_at, device_started_at,
             cancelled_reason
      FROM trips
      """;

  private final JdbcTemplate jdbc;

  public JdbcTripRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public int createScheduled(List<ScheduledRun> runs, LocalDate serviceDate, UUID actorUserId) {
    if (runs.isEmpty()) {
      return 0;
    }

    int created = 0;
    for (ScheduledRun run : runs) {
      created +=
          jdbc.update(
              """
              INSERT INTO trips (tenant_id, school_id, route_id, service_date, direction,
                                 status, scheduled_start_time, created_by, updated_by)
              VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                      ?, ?, ?, ?, 'SCHEDULED', ?, ?, ?)
              ON CONFLICT (tenant_id, route_id, service_date, direction) DO NOTHING
              """,
              run.schoolId(),
              run.routeId(),
              serviceDate,
              run.direction().name(),
              Time.valueOf(run.scheduledStartTime()),
              actorUserId,
              actorUserId);
    }
    return created;
  }

  @Override
  public Optional<Trip> findById(UUID tripId) {
    return jdbc.query(SELECT_COLUMNS + " WHERE id = ?", MAPPER, tripId).stream().findFirst();
  }

  @Override
  public List<Trip> findBySchoolAndDate(UUID schoolId, LocalDate serviceDate) {
    return jdbc.query(
        SELECT_COLUMNS
            + """
             WHERE school_id = ? AND service_date = ?
             ORDER BY scheduled_start_time NULLS LAST, direction
            """,
        MAPPER,
        schoolId,
        serviceDate);
  }

  @Override
  public List<CrewTrip> findForStaffOnDate(UUID staffId, LocalDate serviceDate) {
    // The standing roster, not a per-trip crew table — trip_staff does not exist yet (V13 notes
    // the same). A duty assignment with a null direction covers both runs, which is how most crew
    // are rostered.
    //
    // The joins to routes and vehicles carry the run's identity and the bus it normally uses:
    // a DRIVER holds no PERM-VEHICLE-VIEW, so the app has no other way to name the vehicle it is
    // about to ask them to confirm. LEFT JOIN on the vehicle — a route with no default is a real
    // state, and the app says so rather than showing a blank chip.
    return jdbc.query(
        """
        SELECT t.id, t.school_id, t.route_id, t.vehicle_id, t.service_date, t.direction, t.status,
               t.scheduled_start_time, t.started_at, t.ended_at, t.closed_at, t.device_started_at,
               t.cancelled_reason,
               r.code AS route_code,
               r.name AS route_name,
               (SELECT count(*) FROM stops s WHERE s.route_id = r.id AND s.is_active)
                   AS stop_count,
               dv.id              AS expected_vehicle_id,
               dv.display_name    AS expected_vehicle_display_name,
               dv.registration_no AS expected_vehicle_registration_no
        FROM trips t
        JOIN routes r ON r.id = t.route_id
        LEFT JOIN vehicles dv ON dv.id = r.default_vehicle_id
        WHERE t.service_date = ?
          AND EXISTS (
              SELECT 1
              FROM duty_assignments da
              WHERE da.route_id = t.route_id
                AND da.staff_id = ?
                AND da.is_active
                AND (da.direction IS NULL OR da.direction = t.direction)
                AND da.effective_from <= t.service_date
                AND (da.effective_until IS NULL OR da.effective_until >= t.service_date)
          )
        ORDER BY t.scheduled_start_time NULLS LAST, t.direction
        """,
        (rs, rowNum) ->
            new CrewTrip(
                MAPPER.mapRow(rs, rowNum),
                rs.getString("route_code"),
                rs.getString("route_name"),
                String.valueOf(rs.getInt("stop_count")),
                rs.getObject("expected_vehicle_id", UUID.class),
                rs.getString("expected_vehicle_display_name"),
                rs.getString("expected_vehicle_registration_no")),
        serviceDate,
        staffId);
  }

  @Override
  public boolean start(UUID tripId, UUID vehicleId, Instant startedAt, Instant deviceStartedAt) {
    int updated =
        jdbc.update(
            """
            UPDATE trips
            SET status = 'IN_PROGRESS',
                vehicle_id = ?,
                started_at = ?,
                device_started_at = ?,
                updated_at = now(),
                version = version + 1
            WHERE id = ? AND status = 'SCHEDULED'
            """,
            vehicleId,
            Timestamp.from(startedAt),
            deviceStartedAt == null ? null : Timestamp.from(deviceStartedAt),
            tripId);
    return updated == 1;
  }

  @Override
  public boolean transition(
      UUID tripId, TripStatus from, TripStatus to, Instant at, String reason) {
    // ended_at and closed_at are set by which transition this is, not by a parameter the caller
    // could get wrong. COMPLETED ends the run; CLOSED closes it; CANCELLED does both ways round —
    // it ends the run and records why, and has no closed_at because reconciliation never ran.
    int updated =
        jdbc.update(
            """
            UPDATE trips
            SET status = ?,
                ended_at   = CASE WHEN ? IN ('COMPLETED', 'CANCELLED') THEN ? ELSE ended_at END,
                closed_at  = CASE WHEN ? = 'CLOSED' THEN ? ELSE closed_at END,
                cancelled_reason = COALESCE(?, cancelled_reason),
                updated_at = now(),
                version = version + 1
            WHERE id = ? AND status = ?
            """,
            to.name(),
            to.name(),
            Timestamp.from(at),
            to.name(),
            Timestamp.from(at),
            reason,
            tripId,
            from.name());
    return updated == 1;
  }

  @Override
  public boolean vehicleIsOnAnotherTrip(UUID vehicleId, UUID excludingTripId) {
    Boolean exists =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1 FROM trips
                WHERE vehicle_id = ? AND status = 'IN_PROGRESS' AND id <> ?
            )
            """,
            Boolean.class,
            vehicleId,
            excludingTripId);
    return Boolean.TRUE.equals(exists);
  }

  @Override
  public boolean staffIsOnAnotherTrip(UUID staffId, UUID excludingTripId) {
    Boolean exists =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1
                FROM trips t
                JOIN duty_assignments da
                  ON da.route_id = t.route_id
                 AND da.is_active
                 AND (da.direction IS NULL OR da.direction = t.direction)
                WHERE da.staff_id = ? AND t.status = 'IN_PROGRESS' AND t.id <> ?
            )
            """,
            Boolean.class,
            staffId,
            excludingTripId);
    return Boolean.TRUE.equals(exists);
  }

  @Override
  public boolean isRosteredCrewFor(UUID tripId, UUID staffId) {
    Boolean exists =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1
                FROM trips t
                JOIN duty_assignments da
                  ON da.route_id = t.route_id
                 AND da.is_active
                 AND (da.direction IS NULL OR da.direction = t.direction)
                 AND da.effective_from <= t.service_date
                 AND (da.effective_until IS NULL OR da.effective_until >= t.service_date)
                WHERE t.id = ? AND da.staff_id = ?
            )
            """,
            Boolean.class,
            tripId,
            staffId);
    return Boolean.TRUE.equals(exists);
  }

  private static final RowMapper<Trip> MAPPER =
      (ResultSet rs, int rowNum) ->
          new Trip(
              rs.getObject("id", UUID.class),
              rs.getObject("school_id", UUID.class),
              rs.getObject("route_id", UUID.class),
              rs.getObject("vehicle_id", UUID.class),
              rs.getObject("service_date", LocalDate.class),
              TripDirection.valueOf(rs.getString("direction")),
              TripStatus.valueOf(rs.getString("status")),
              localTime(rs, "scheduled_start_time"),
              instant(rs, "started_at"),
              instant(rs, "ended_at"),
              instant(rs, "closed_at"),
              instant(rs, "device_started_at"),
              rs.getString("cancelled_reason"));

  private static LocalTime localTime(ResultSet rs, String column) throws SQLException {
    Time value = rs.getTime(column);
    return value == null ? null : value.toLocalTime();
  }

  private static Instant instant(ResultSet rs, String column) throws SQLException {
    Timestamp value = rs.getTimestamp(column);
    return value == null ? null : value.toInstant();
  }
}
