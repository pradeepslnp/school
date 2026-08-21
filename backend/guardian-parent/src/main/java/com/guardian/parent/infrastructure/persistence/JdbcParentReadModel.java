package com.guardian.parent.infrastructure.persistence;

import com.guardian.parent.application.port.ParentReadModel;
import com.guardian.parent.application.result.ChildDetailView;
import com.guardian.parent.application.result.DashboardView;
import com.guardian.parent.application.result.JourneyHistoryView;
import com.guardian.parent.domain.ChildJourney;
import com.guardian.parent.domain.JourneyHistoryEntry;
import com.guardian.parent.domain.JourneyLeg;
import com.guardian.parent.domain.JourneyState;
import com.guardian.parent.domain.SchoolClock;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * The parent app's cross-module projection — the whole of the coupling ADR-0010 accepts, in one
 * file.
 *
 * <p>It reads tables owned by MOD-03 (students), MOD-04 (guardian links), MOD-05 (vehicles), MOD-07
 * (routes, stops, assignments), MOD-08 (trips, manifests), MOD-09 (boarding events) and MOD-14
 * (absences). That is a deliberate, bounded exception to "a module owns its tables", argued in
 * ADR-0010 and contained here rather than spread across the module.
 *
 * <p><strong>Three properties are load-bearing.</strong>
 *
 * <ul>
 *   <li><em>Scope lives in the WHERE clause.</em> Every query joins {@code guardian_student_links}
 *       on the calling guardian, so a child they hold no active link to is not in the result set at
 *       all (BR-IAM-005). There is no post-filter to forget, and no code path where the full set
 *       exists in memory.
 *   <li><em>Journey state is derived here, not stored.</em> No column holds it; it is computed from
 *       today's trip, the manifest row, the boarding events, and any absence. A stored copy would
 *       be a second source of truth that drifts from the boarding record — and the boarding record
 *       is the evidence.
 *   <li><em>One query per screen.</em> The dashboard is a single statement, not a loop over
 *       children. On a phone at 07:40 that difference is the product.
 * </ul>
 *
 * <p>Row-level security still applies to every statement below; this relaxes module boundaries,
 * never tenant boundaries.
 */
@Component
public class JdbcParentReadModel implements ParentReadModel {

  private final JdbcTemplate jdbc;

  public JdbcParentReadModel(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  /**
   * The dashboard projection.
   *
   * <p>Reads as four stages: resolve the caller's children, attach today's trip for each direction,
   * attach the boarding facts, then fold it into one state per child.
   *
   * <p>{@code today} is computed in the <em>school's</em> timezone, not the server's (BR-CFG-006).
   * A school in Asia/Kolkata rolls into a new service date five and a half hours before a UTC
   * server does, so {@code CURRENT_DATE} would show an empty dashboard all evening.
   */
  private static final String CHILDREN_SQL =
      """
      WITH linked AS (
          -- Scope. Everything below is inner-joined to this, so a child the caller holds no
          -- active link to cannot appear in any later stage (BR-IAM-005).
          SELECT s.id            AS student_id,
                 s.first_name || ' ' || s.last_name AS display_name,
                 sc.grade || '-' || sc.section      AS class_name,
                 sch.id          AS school_id,
                 sch.timezone    AS school_timezone
          FROM guardian_student_links gsl
          JOIN guardians g   ON g.id = gsl.guardian_id AND g.is_active
          JOIN students  s   ON s.id = gsl.student_id
          JOIN schools   sch ON sch.id = s.school_id
          LEFT JOIN student_classes sc ON sc.id = s.student_class_id
          WHERE g.user_id = ?
            AND gsl.is_active
            AND gsl.can_view
            AND s.enrolment_status = 'ACTIVE'
      ),
      today AS (
          SELECT l.student_id,
                 (now() AT TIME ZONE l.school_timezone)::date AS service_date
          FROM linked l
      ),
      leg AS (
          -- One row per child per direction that has a trip today. LEFT JOINs throughout: a
          -- child with no trip at all is still a child the dashboard must show, calmly.
          SELECT l.student_id,
                 t.id            AS trip_id,
                 t.direction,
                 t.status        AS trip_status,
                 t.started_at,
                 t.closed_at,
                 v.display_name  AS vehicle_display_name,
                 st.name         AS stop_name,
                 tm.status       AS manifest_status,
                 -- Scheduled departure as an instant, rebuilt from the stop's school-local
                 -- wall-clock time in the school's zone. Composing it here keeps the client
                 -- free of timezone arithmetic entirely.
                 CASE
                     WHEN st.scheduled_pickup_time IS NOT NULL AND t.direction = 'PICKUP'
                         THEN (td.service_date + st.scheduled_pickup_time)
                              AT TIME ZONE l.school_timezone
                     WHEN st.scheduled_drop_time IS NOT NULL AND t.direction = 'DROP'
                         THEN (td.service_date + st.scheduled_drop_time)
                              AT TIME ZONE l.school_timezone
                 END AS scheduled_at,
                 (SELECT max(be.occurred_at) FROM boarding_events be
                   WHERE be.trip_id = t.id AND be.student_id = l.student_id
                     AND be.event_type = 'BOARD')  AS boarded_at,
                 (SELECT max(be.occurred_at) FROM boarding_events be
                   WHERE be.trip_id = t.id AND be.student_id = l.student_id
                     AND be.event_type = 'ALIGHT') AS alighted_at
          FROM linked l
          JOIN today td ON td.student_id = l.student_id
          JOIN route_student_assignments rsa
                 ON rsa.student_id = l.student_id AND rsa.is_active
          JOIN stops st ON st.id = rsa.stop_id
          JOIN trips t
                 ON t.route_id = rsa.route_id
                AND t.direction = rsa.direction
                AND t.service_date = td.service_date
                AND t.status <> 'CANCELLED'
          LEFT JOIN trip_manifests tm ON tm.trip_id = t.id AND tm.student_id = l.student_id
          LEFT JOIN vehicles v ON v.id = t.vehicle_id
      ),
      absence AS (
          SELECT DISTINCT l.student_id
          FROM linked l
          JOIN today td ON td.student_id = l.student_id
          JOIN absences a
                 ON a.student_id = l.student_id
                AND a.status = 'ACTIVE'
                AND td.service_date BETWEEN a.from_date AND a.to_date
      ),
      current_leg AS (
          -- The leg that describes the child *now*: an in-progress trip wins over a finished
          -- one, and a finished one over a merely scheduled one. Without this ordering a
          -- child on a bus could be reported by their completed morning run.
          SELECT DISTINCT ON (student_id) *
          FROM leg
          ORDER BY student_id,
                   CASE trip_status
                       WHEN 'IN_PROGRESS' THEN 0
                       WHEN 'COMPLETED'   THEN 1
                       WHEN 'CLOSED'      THEN 2
                       ELSE 3
                   END,
                   started_at DESC NULLS LAST
      )
      SELECT l.student_id,
             l.display_name,
             l.class_name,
             l.school_timezone,
             cl.trip_id,
             cl.direction,
             cl.trip_status,
             cl.vehicle_display_name,
             cl.stop_name,
             cl.manifest_status,
             cl.boarded_at,
             cl.alighted_at,
             cl.scheduled_at,
             -- The next departure still ahead today, which is what keeps an idle card calm
             -- rather than empty ("At school · next bus 15:10").
             (SELECT min(nl.scheduled_at) FROM leg nl
               WHERE nl.student_id = l.student_id
                 AND nl.scheduled_at > now()
                 AND nl.trip_status IN ('SCHEDULED', 'IN_PROGRESS')) AS next_departure_at,
             (a.student_id IS NOT NULL) AS is_absent
      FROM linked l
      LEFT JOIN current_leg cl ON cl.student_id = l.student_id
      LEFT JOIN absence a      ON a.student_id = l.student_id
      ORDER BY l.display_name
      """;

  @Override
  public DashboardView childrenOf(UUID guardianUserId) {
    Instant observedAt = Instant.now();
    List<Row> rows = jdbc.query(CHILDREN_SQL, ROW_MAPPER, guardianUserId);

    List<ChildJourney> children = new ArrayList<>(rows.size());
    SchoolClock clock = null;
    for (Row row : rows) {
      children.add(row.toJourney());
      if (clock == null && row.schoolTimezone() != null) {
        clock = SchoolClock.of(row.schoolTimezone());
      }
    }
    // Null clock only when the guardian has no linked children — there is then no school to
    // report, and the caller omits meta.school rather than inventing UTC.
    return new DashboardView(children, clock, observedAt);
  }

  /**
   * Child detail: the same current state, plus every leg of today.
   *
   * <p>Two statements rather than one. The dashboard query is shaped to return exactly one row per
   * child; a detail view needs all of a child's legs, and folding both shapes into one statement
   * would make the hot path pay for the cold one.
   */
  @Override
  public Optional<ChildDetailView> childDetail(UUID guardianUserId, UUID studentId) {
    Instant observedAt = Instant.now();

    // Reuses the dashboard projection and picks the child out in memory. That is safe rather
    // than sloppy: the query already returns only children the caller is linked to, so a
    // student they are not linked to is absent from the list and the filter below cannot
    // reach one. The set is a family's children, not a school's.
    List<Row> rows = jdbc.query(CHILDREN_SQL, ROW_MAPPER, guardianUserId);
    Optional<Row> match = rows.stream().filter(r -> studentId.equals(r.studentId())).findFirst();
    if (match.isEmpty()) {
      // Not linked, or does not exist. The use case turns both into the same refusal, so this
      // layer does not need to tell them apart.
      return Optional.empty();
    }

    Row row = match.get();
    List<JourneyLeg> legs = jdbc.query(LEGS_SQL, LEG_MAPPER, guardianUserId, studentId);
    SchoolClock clock = row.schoolTimezone() == null ? null : SchoolClock.of(row.schoolTimezone());

    return Optional.of(new ChildDetailView(row.toJourney(), legs, clock, observedAt));
  }

  /**
   * Every leg of today for one child, in operational order. Scoped identically to the dashboard.
   */
  private static final String LEGS_SQL =
      """
      WITH linked AS (
          SELECT s.id AS student_id, sch.timezone AS school_timezone
          FROM guardian_student_links gsl
          JOIN guardians g   ON g.id = gsl.guardian_id AND g.is_active
          JOIN students  s   ON s.id = gsl.student_id
          JOIN schools   sch ON sch.id = s.school_id
          WHERE g.user_id = ? AND gsl.is_active AND gsl.can_view AND s.id = ?
      )
      SELECT t.id AS trip_id,
             t.direction,
             t.status AS trip_status,
             v.display_name AS vehicle_display_name,
             st.name AS stop_name,
             CASE
                 WHEN t.direction = 'PICKUP' THEN
                     ((now() AT TIME ZONE l.school_timezone)::date + st.scheduled_pickup_time)
                     AT TIME ZONE l.school_timezone
                 ELSE
                     ((now() AT TIME ZONE l.school_timezone)::date + st.scheduled_drop_time)
                     AT TIME ZONE l.school_timezone
             END AS scheduled_at,
             tm.status AS manifest_status,
             (SELECT max(be.occurred_at) FROM boarding_events be
               WHERE be.trip_id = t.id AND be.student_id = l.student_id
                 AND be.event_type = 'BOARD')  AS boarded_at,
             (SELECT max(be.occurred_at) FROM boarding_events be
               WHERE be.trip_id = t.id AND be.student_id = l.student_id
                 AND be.event_type = 'ALIGHT') AS alighted_at,
             EXISTS (SELECT 1 FROM absences a
                      WHERE a.student_id = l.student_id AND a.status = 'ACTIVE'
                        AND (now() AT TIME ZONE l.school_timezone)::date
                            BETWEEN a.from_date AND a.to_date
                        AND (a.direction IS NULL OR a.direction = t.direction)) AS is_absent
      FROM linked l
      JOIN route_student_assignments rsa ON rsa.student_id = l.student_id AND rsa.is_active
      JOIN stops st ON st.id = rsa.stop_id
      JOIN trips t
             ON t.route_id = rsa.route_id
            AND t.direction = rsa.direction
            AND t.service_date = (now() AT TIME ZONE l.school_timezone)::date
            AND t.status <> 'CANCELLED'
      LEFT JOIN trip_manifests tm ON tm.trip_id = t.id AND tm.student_id = l.student_id
      LEFT JOIN vehicles v ON v.id = t.vehicle_id
      ORDER BY CASE t.direction WHEN 'PICKUP' THEN 0 ELSE 1 END
      """;

  /**
   * P-05 — one child's past journeys.
   *
   * <p>Driven from {@code trips} rather than from {@code boarding_events}, which is the difference
   * between a useful history and a misleading one: a day the child did <em>not</em> board is
   * exactly the day a parent scrolls back to find, and an event-driven query cannot show a leg that
   * produced no event.
   */
  private static final String HISTORY_SQL =
      """
      WITH linked AS (
          SELECT s.id AS student_id, sch.timezone AS school_timezone
          FROM guardian_student_links gsl
          JOIN guardians g   ON g.id = gsl.guardian_id AND g.is_active
          JOIN students  s   ON s.id = gsl.student_id
          JOIN schools   sch ON sch.id = s.school_id
          WHERE g.user_id = ? AND gsl.is_active AND gsl.can_view AND s.id = ?
      )
      SELECT l.school_timezone,
             t.service_date,
             t.direction,
             t.status AS trip_status,
             v.display_name AS vehicle_display_name,
             st.name AS stop_name,
             tm.status AS manifest_status,
             (SELECT max(be.occurred_at) FROM boarding_events be
               WHERE be.trip_id = t.id AND be.student_id = l.student_id
                 AND be.event_type = 'BOARD')  AS boarded_at,
             (SELECT max(be.occurred_at) FROM boarding_events be
               WHERE be.trip_id = t.id AND be.student_id = l.student_id
                 AND be.event_type = 'ALIGHT') AS alighted_at,
             EXISTS (SELECT 1 FROM absences a
                      WHERE a.student_id = l.student_id AND a.status = 'ACTIVE'
                        AND t.service_date BETWEEN a.from_date AND a.to_date
                        AND (a.direction IS NULL OR a.direction = t.direction)) AS is_absent
      FROM linked l
      -- Through the manifest, so history reflects who was actually expected on each run rather
      -- than today's route assignment applied backwards over past dates.
      JOIN trip_manifests tm ON tm.student_id = l.student_id
      JOIN trips t  ON t.id = tm.trip_id AND t.status <> 'CANCELLED'
      JOIN stops st ON st.id = tm.expected_stop_id
      LEFT JOIN vehicles v ON v.id = t.vehicle_id
      WHERE t.service_date <= (now() AT TIME ZONE l.school_timezone)::date
      ORDER BY t.service_date DESC,
               CASE t.direction WHEN 'DROP' THEN 0 ELSE 1 END
      LIMIT ?
      """;

  @Override
  public JourneyHistoryView journeyHistory(UUID guardianUserId, UUID studentId, int limit) {
    Instant observedAt = Instant.now();
    List<HistoryRow> rows =
        jdbc.query(HISTORY_SQL, HISTORY_MAPPER, guardianUserId, studentId, limit);

    List<JourneyHistoryEntry> entries = new ArrayList<>(rows.size());
    SchoolClock clock = null;
    for (HistoryRow row : rows) {
      entries.add(row.entry());
      if (clock == null && row.schoolTimezone() != null) {
        clock = SchoolClock.of(row.schoolTimezone());
      }
    }
    return new JourneyHistoryView(entries, clock, observedAt);
  }

  // --- state derivation ------------------------------------------------------------------

  /**
   * Folds trip status, manifest status, boarding events and absence into one journey state.
   *
   * <p>Order matters and is not arbitrary:
   *
   * <ol>
   *   <li><strong>Boarded with no alight on a closed trip is UNACCOUNTED</strong> and is checked
   *       first, because it is the one state that must never be masked by a cheerier one
   *       (BR-SAFE-001 🔴).
   *   <li>Absence is checked before trip state: a child declared absent is not a no-show, and
   *       telling a parent their child "did not board" when the parent themselves said they were
   *       not travelling is alarming and wrong (BR-ABS-005).
   *   <li>Actual events beat expectations. A boarding record is evidence; a manifest row is a plan.
   * </ol>
   */
  private static JourneyState deriveState(
      String tripStatus,
      String manifestStatus,
      Instant boardedAt,
      Instant alightedAt,
      String direction,
      boolean absent) {

    if (tripStatus == null) {
      // No trip today for this child at all.
      return absent ? JourneyState.ABSENT : JourneyState.AT_REST;
    }

    boolean boarded = boardedAt != null;
    boolean alighted = alightedAt != null;
    boolean tripFinished = "COMPLETED".equals(tripStatus) || "CLOSED".equals(tripStatus);

    if (boarded && !alighted && "CLOSED".equals(tripStatus)) {
      return JourneyState.UNACCOUNTED;
    }
    if (absent) {
      return JourneyState.ABSENT;
    }
    if (boarded && alighted) {
      // Where they got off is what distinguishes these: at school on the way in, into someone's
      // care on the way home.
      return "PICKUP".equals(direction) ? JourneyState.ARRIVED_AT_SCHOOL : JourneyState.HANDED_OVER;
    }
    if (boarded) {
      return JourneyState.ON_BOARD;
    }
    if ("NO_SHOW".equals(manifestStatus) || (tripFinished && "EXPECTED".equals(manifestStatus))) {
      // A finished trip that still expected this child means the bus came and went without them.
      return JourneyState.NO_SHOW;
    }
    if ("IN_PROGRESS".equals(tripStatus)) {
      return JourneyState.AWAITING_BOARDING;
    }
    if (tripFinished) {
      // Finished, never on the manifest: nothing was expected of this child on this run.
      return JourneyState.AT_REST;
    }
    return JourneyState.SCHEDULED;
  }

  // --- row mapping -----------------------------------------------------------------------

  /** Flat carrier for the dashboard query, so the fold above stays readable. */
  private record Row(
      UUID studentId,
      String displayName,
      String className,
      String schoolTimezone,
      UUID tripId,
      String direction,
      String tripStatus,
      String vehicleDisplayName,
      String stopName,
      String manifestStatus,
      Instant boardedAt,
      Instant alightedAt,
      Instant scheduledAt,
      Instant nextDepartureAt,
      boolean absent) {

    ChildJourney toJourney() {
      JourneyState state =
          deriveState(tripStatus, manifestStatus, boardedAt, alightedAt, direction, absent);

      return new ChildJourney(
          studentId,
          displayName,
          className,
          state,
          // Only when tracking is actually offered, so the app never renders a Track button
          // that opens a screen refusing the trip (BR-TRACK-001).
          state.permitsLiveTracking() ? tripId : null,
          vehicleDisplayName,
          stopName,
          // The most recent thing that actually happened, which is what the card's sentence
          // describes.
          alightedAt != null ? alightedAt : boardedAt,
          // ETA is not computed here: it belongs to MOD-10 and is served from Redis
          // (ADR-0004). Sending a scheduled time as an estimate would put a number on screen
          // that nothing measured (BR-TRACK-006).
          null,
          nextDepartureAt,
          null,
          null);
    }
  }

  private static final RowMapper<Row> ROW_MAPPER =
      (ResultSet rs, int rowNum) ->
          new Row(
              rs.getObject("student_id", UUID.class),
              rs.getString("display_name"),
              rs.getString("class_name"),
              rs.getString("school_timezone"),
              rs.getObject("trip_id", UUID.class),
              rs.getString("direction"),
              rs.getString("trip_status"),
              rs.getString("vehicle_display_name"),
              rs.getString("stop_name"),
              rs.getString("manifest_status"),
              instant(rs, "boarded_at"),
              instant(rs, "alighted_at"),
              instant(rs, "scheduled_at"),
              instant(rs, "next_departure_at"),
              rs.getBoolean("is_absent"));

  private static final RowMapper<JourneyLeg> LEG_MAPPER =
      (ResultSet rs, int rowNum) -> {
        String direction = rs.getString("direction");
        Instant boardedAt = instant(rs, "boarded_at");
        Instant alightedAt = instant(rs, "alighted_at");

        return new JourneyLeg(
            rs.getObject("trip_id", UUID.class),
            "PICKUP".equals(direction) ? JourneyLeg.Direction.PICKUP : JourneyLeg.Direction.DROP,
            deriveState(
                rs.getString("trip_status"),
                rs.getString("manifest_status"),
                boardedAt,
                alightedAt,
                direction,
                rs.getBoolean("is_absent")),
            rs.getString("vehicle_display_name"),
            rs.getString("stop_name"),
            instant(rs, "scheduled_at"),
            alightedAt != null ? alightedAt : boardedAt);
      };

  /** An entry plus the school it belongs to, so the clock is read from the same query. */
  private record HistoryRow(String schoolTimezone, JourneyHistoryEntry entry) {}

  private static final RowMapper<HistoryRow> HISTORY_MAPPER =
      (ResultSet rs, int rowNum) -> {
        String direction = rs.getString("direction");
        Instant boardedAt = instant(rs, "boarded_at");
        Instant alightedAt = instant(rs, "alighted_at");

        return new HistoryRow(
            rs.getString("school_timezone"),
            new JourneyHistoryEntry(
                rs.getObject("service_date", LocalDate.class),
                "PICKUP".equals(direction)
                    ? JourneyLeg.Direction.PICKUP
                    : JourneyLeg.Direction.DROP,
                deriveState(
                    rs.getString("trip_status"),
                    rs.getString("manifest_status"),
                    boardedAt,
                    alightedAt,
                    direction,
                    rs.getBoolean("is_absent")),
                rs.getString("vehicle_display_name"),
                rs.getString("stop_name"),
                alightedAt != null ? alightedAt : boardedAt));
      };

  /**
   * Reads a nullable timestamp as an {@link Instant}.
   *
   * <p>{@code getTimestamp} returns null for SQL NULL but {@code toInstant()} would throw on it,
   * and a null here is ordinary — most children have not boarded yet at 07:00.
   */
  private static Instant instant(ResultSet rs, String column) throws SQLException {
    Timestamp value = rs.getTimestamp(column);
    return value == null ? null : value.toInstant();
  }
}
