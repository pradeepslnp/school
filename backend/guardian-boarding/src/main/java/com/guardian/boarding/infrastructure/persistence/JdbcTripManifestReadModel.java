package com.guardian.boarding.infrastructure.persistence;

import com.guardian.boarding.application.port.TripManifestReadModel;
import com.guardian.boarding.application.result.ManifestEntry;
import com.guardian.boarding.domain.ManifestEntryStatus;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * Reads a trip's manifest for the crew's screen (TRP-003).
 *
 * <p>Ordered by stop sequence, then by name. The sequence is the order the bus meets the children,
 * and it is the only order a forty-name list is usable in at a kerb; the name is a tiebreak so two
 * children at the same stop do not swap places between refreshes, which is how a crew loses their
 * place mid-count.
 *
 * <p>The scheduled time is read for the child's <em>own</em> direction: a pickup manifest shows
 * when the bus is due at their stop, a drop manifest when they are due to be let off.
 */
@Component
public class JdbcTripManifestReadModel implements TripManifestReadModel {

  private final JdbcTemplate jdbc;

  public JdbcTripManifestReadModel(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public List<ManifestEntry> manifestFor(UUID tripId) {
    return jdbc.query(
        """
        SELECT tm.student_id,
               tm.student_name_snapshot,
               tm.expected_stop_id,
               tm.sequence_no,
               tm.status,
               st.name AS stop_name,
               CASE t.direction
                   WHEN 'PICKUP' THEN st.scheduled_pickup_time
                   ELSE st.scheduled_drop_time
               END AS scheduled_stop_time,
               sc.name AS class_name,
               (SELECT max(be.occurred_at)
                  FROM boarding_events be
                 WHERE be.trip_id = tm.trip_id AND be.student_id = tm.student_id) AS last_event_at
        FROM trip_manifests tm
        JOIN trips t ON t.id = tm.trip_id
        JOIN stops st ON st.id = tm.expected_stop_id
        LEFT JOIN students s ON s.id = tm.student_id
        LEFT JOIN student_classes sc ON sc.id = s.student_class_id
        WHERE tm.trip_id = ?
        ORDER BY tm.sequence_no, tm.student_name_snapshot
        """,
        MAPPER,
        tripId);
  }

  @Override
  public Optional<String> statusOf(UUID tripId) {
    return jdbc
        .query(
            "SELECT status FROM trips WHERE id = ?",
            (rs, rowNum) -> rs.getString("status"),
            tripId)
        .stream()
        .findFirst();
  }

  private static final RowMapper<ManifestEntry> MAPPER =
      (ResultSet rs, int rowNum) ->
          new ManifestEntry(
              rs.getObject("student_id", UUID.class),
              rs.getString("student_name_snapshot"),
              rs.getString("class_name"),
              rs.getObject("expected_stop_id", UUID.class),
              rs.getString("stop_name"),
              rs.getInt("sequence_no"),
              localTime(rs, "scheduled_stop_time"),
              ManifestEntryStatus.valueOf(rs.getString("status")),
              instant(rs, "last_event_at"));

  private static LocalTime localTime(ResultSet rs, String column) throws SQLException {
    Time value = rs.getTime(column);
    return value == null ? null : value.toLocalTime();
  }

  private static Instant instant(ResultSet rs, String column) throws SQLException {
    Timestamp value = rs.getTimestamp(column);
    return value == null ? null : value.toInstant();
  }
}
