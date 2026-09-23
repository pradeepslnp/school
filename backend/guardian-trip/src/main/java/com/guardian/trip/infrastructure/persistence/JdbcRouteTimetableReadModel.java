package com.guardian.trip.infrastructure.persistence;

import com.guardian.trip.application.port.RouteTimetableReadModel;
import com.guardian.trip.domain.CalendarException;
import com.guardian.trip.domain.ScheduledRun;
import com.guardian.trip.domain.TripDirection;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * Answers "which runs should exist on this date?" in one statement (BR-TRIP-011).
 *
 * <p>All of the rule is expressed in SQL rather than by loading routes and filtering in Java,
 * because every clause is a set operation the database does better and because the alternative is
 * three round trips per route. Each clause, in the order it appears:
 *
 * <ul>
 *   <li><strong>{@code r.is_active}</strong> — a retired route does not run.
 *   <li><strong>The weekday is in {@code operating_days}</strong>, unless the school has declared
 *       the date a {@code WORKING_DAY}. Matched with {@code string_to_array} rather than {@code
 *       LIKE '%MON%'}: the substring test would match {@code MON} inside nothing today, but it is
 *       the kind of clever that breaks the first time a code is added.
 *   <li><strong>The school has not declared the date a {@code HOLIDAY}</strong>. A holiday beats
 *       everything, including a working-day exception for the same date — which the unique
 *       constraint on (school, date) makes unrepresentable anyway.
 *   <li><strong>The run has a timetable.</strong> The join to {@code stops} takes the earliest
 *       scheduled time for the direction, and {@code MIN} over no rows is null, so a route with no
 *       timed stops for a direction simply produces no row for it. That is why there is no separate
 *       "which directions does this route run" column to keep in step.
 * </ul>
 *
 * <p>The tenant is not named anywhere: row-level security scopes every table involved, and the
 * caller has already established context.
 */
@Component
public class JdbcRouteTimetableReadModel implements RouteTimetableReadModel {

  private static final RowMapper<ScheduledRun> MAPPER =
      (ResultSet rs, int rowNum) ->
          new ScheduledRun(
              rs.getObject("route_id", java.util.UUID.class),
              rs.getObject("school_id", java.util.UUID.class),
              TripDirection.valueOf(rs.getString("direction")),
              rs.getTime("scheduled_start_time").toLocalTime());

  private static final String SQL =
      """
      WITH calendar AS (
          SELECT school_id, exception_type
          FROM school_calendar_exceptions
          WHERE exception_date = ?
      ),
      timetable AS (
          SELECT r.id            AS route_id,
                 r.school_id     AS school_id,
                 r.operating_days,
                 MIN(st.scheduled_pickup_time) AS pickup_start,
                 MIN(st.scheduled_drop_time)   AS drop_start
          FROM routes r
          JOIN stops st ON st.route_id = r.id AND st.is_active
          WHERE r.is_active
          GROUP BY r.id, r.school_id, r.operating_days
      ),
      operating AS (
          SELECT t.*
          FROM timetable t
          LEFT JOIN calendar c ON c.school_id = t.school_id
          WHERE COALESCE(c.exception_type, '') <> ?
            AND (
                  ? = ANY (string_to_array(t.operating_days, ','))
                  OR c.exception_type = ?
                )
      )
      SELECT route_id, school_id, 'PICKUP' AS direction, pickup_start AS scheduled_start_time
      FROM operating
      WHERE pickup_start IS NOT NULL
      UNION ALL
      SELECT route_id, school_id, 'DROP' AS direction, drop_start AS scheduled_start_time
      FROM operating
      WHERE drop_start IS NOT NULL
      ORDER BY scheduled_start_time, route_id
      """;

  private final JdbcTemplate jdbc;

  public JdbcRouteTimetableReadModel(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public List<ScheduledRun> runsFor(LocalDate serviceDate) {
    return jdbc.query(
        SQL,
        MAPPER,
        serviceDate,
        CalendarException.HOLIDAY.name(),
        dayCode(serviceDate),
        CalendarException.WORKING_DAY.name());
  }

  /**
   * The three-letter code stored in {@code operating_days}.
   *
   * <p>Derived in Java from {@link java.time.DayOfWeek} rather than with PostgreSQL's {@code
   * to_char(..., 'DY')}, which is locale-dependent and would return {@code ಸೋಮ} on a server with an
   * Indian locale — a bug that would appear only in the deployment it matters in.
   */
  private static String dayCode(LocalDate date) {
    return switch (date.getDayOfWeek()) {
      case MONDAY -> "MON";
      case TUESDAY -> "TUE";
      case WEDNESDAY -> "WED";
      case THURSDAY -> "THU";
      case FRIDAY -> "FRI";
      case SATURDAY -> "SAT";
      case SUNDAY -> "SUN";
    };
  }
}
