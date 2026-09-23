package com.guardian.boarding.infrastructure.persistence;

import com.guardian.boarding.application.port.BoardingEventRepository;
import com.guardian.boarding.domain.BoardingEvent;
import com.guardian.boarding.domain.BoardingEventType;
import com.guardian.boarding.domain.ManifestEntryStatus;
import com.guardian.boarding.domain.VerificationMethod;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code boarding_events} (MOD-09).
 *
 * <p>Append-only in fact, not just by convention: the only statements here are {@code INSERT} and
 * {@code SELECT}, apart from the one {@code UPDATE} that maintains the manifest projection. There
 * is deliberately no update or delete of an event, so no future caller can find one to use
 * (BR-BOARD-001 🔴).
 *
 * <p>Every statement runs under row-level security, so tenant scoping is not repeated in the SQL.
 */
@Component
public class JdbcBoardingEventRepository implements BoardingEventRepository {

  private static final String SELECT_COLUMNS =
      """
      SELECT id, trip_id, student_id, stop_id, event_type, verification_method,
             actor_id, actor_role, client_event_id, corrects_event_id, is_override,
             override_reason, occurred_at, recorded_at, clock_skew_seconds,
             device_latitude, device_longitude
      FROM boarding_events
      """;

  private final JdbcTemplate jdbc;

  public JdbcBoardingEventRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public Optional<BoardingEvent> findByClientEventId(UUID clientEventId) {
    return jdbc.query(SELECT_COLUMNS + " WHERE client_event_id = ?", MAPPER, clientEventId).stream()
        .findFirst();
  }

  @Override
  public BoardingEvent append(BoardingEvent event) {
    return insert(event, "SYNCED");
  }

  @Override
  public BoardingEvent appendFlagged(BoardingEvent event) {
    return insert(event, "FLAGGED_FOR_REVIEW");
  }

  private BoardingEvent insert(BoardingEvent event, String syncState) {
    UUID id =
        jdbc.queryForObject(
            """
            INSERT INTO boarding_events (tenant_id, trip_id, student_id, stop_id, event_type,
                                         verification_method, actor_id, actor_role,
                                         client_event_id, corrects_event_id, is_override,
                                         override_reason, occurred_at, recorded_at,
                                         clock_skew_seconds, device_latitude, device_longitude,
                                         sync_state)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            RETURNING id
            """,
            UUID.class,
            event.tripId(),
            event.studentId(),
            event.stopId(),
            event.eventType().name(),
            event.verificationMethod().name(),
            event.actorId(),
            event.actorRole(),
            event.clientEventId(),
            event.correctsEventId(),
            event.isOverride(),
            event.overrideReason(),
            Timestamp.from(event.occurredAt()),
            Timestamp.from(event.recordedAt()),
            event.clockSkewSeconds(),
            event.deviceLatitude(),
            event.deviceLongitude(),
            syncState);

    return new BoardingEvent(
        id,
        event.tripId(),
        event.studentId(),
        event.stopId(),
        event.eventType(),
        event.verificationMethod(),
        event.actorId(),
        event.actorRole(),
        event.clientEventId(),
        event.correctsEventId(),
        event.isOverride(),
        event.overrideReason(),
        event.occurredAt(),
        event.recordedAt(),
        event.clockSkewSeconds(),
        event.deviceLatitude(),
        event.deviceLongitude());
  }

  @Override
  public Optional<BoardingEventType> lastEventTypeFor(UUID tripId, UUID studentId) {
    // Ordered by the device clock, then by the server's: two events captured offline in the same
    // second sync together, and recorded_at is the only thing left to break the tie.
    return jdbc
        .query(
            """
            SELECT event_type
            FROM boarding_events
            WHERE trip_id = ? AND student_id = ?
            ORDER BY occurred_at DESC, recorded_at DESC
            LIMIT 1
            """,
            (rs, rowNum) -> BoardingEventType.valueOf(rs.getString("event_type")),
            tripId,
            studentId)
        .stream()
        .findFirst();
  }

  @Override
  public boolean isOnManifest(UUID tripId, UUID studentId) {
    Boolean exists =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1 FROM trip_manifests WHERE trip_id = ? AND student_id = ?
            )
            """,
            Boolean.class,
            tripId,
            studentId);
    return Boolean.TRUE.equals(exists);
  }

  @Override
  public Optional<UUID> expectedStopFor(UUID tripId, UUID studentId) {
    return jdbc
        .query(
            "SELECT expected_stop_id FROM trip_manifests WHERE trip_id = ? AND student_id = ?",
            (rs, rowNum) -> rs.getObject("expected_stop_id", UUID.class),
            tripId,
            studentId)
        .stream()
        .findFirst();
  }

  @Override
  public Optional<UUID> otherTripExpectingStudent(UUID tripId, UUID studentId) {
    // BR-SAFE-003 🔴. "Another active trip, same date and direction, whose manifest includes this
    // child." Scoped to IN_PROGRESS on purpose: a child on tomorrow's manifest for a different
    // route is not being put on the wrong bus, they are simply not on this one.
    return jdbc
        .query(
            """
            SELECT other.id
            FROM trips this_trip
            JOIN trips other
              ON other.service_date = this_trip.service_date
             AND other.direction    = this_trip.direction
             AND other.id <> this_trip.id
             AND other.status = 'IN_PROGRESS'
            JOIN trip_manifests tm ON tm.trip_id = other.id AND tm.student_id = ?
            WHERE this_trip.id = ?
            LIMIT 1
            """,
            (rs, rowNum) -> rs.getObject("id", UUID.class),
            studentId,
            tripId)
        .stream()
        .findFirst();
  }

  @Override
  public void updateManifestStatus(UUID tripId, UUID studentId, ManifestEntryStatus status) {
    jdbc.update(
        """
        UPDATE trip_manifests
        SET status = ?, updated_at = now(), version = version + 1
        WHERE trip_id = ? AND student_id = ?
        """,
        status.name(),
        tripId,
        studentId);
  }

  private static final RowMapper<BoardingEvent> MAPPER =
      (ResultSet rs, int rowNum) ->
          new BoardingEvent(
              rs.getObject("id", UUID.class),
              rs.getObject("trip_id", UUID.class),
              rs.getObject("student_id", UUID.class),
              rs.getObject("stop_id", UUID.class),
              BoardingEventType.valueOf(rs.getString("event_type")),
              VerificationMethod.valueOf(rs.getString("verification_method")),
              rs.getObject("actor_id", UUID.class),
              rs.getString("actor_role"),
              rs.getObject("client_event_id", UUID.class),
              rs.getObject("corrects_event_id", UUID.class),
              rs.getBoolean("is_override"),
              rs.getString("override_reason"),
              instant(rs, "occurred_at"),
              instant(rs, "recorded_at"),
              (Integer) rs.getObject("clock_skew_seconds"),
              rs.getBigDecimal("device_latitude"),
              rs.getBigDecimal("device_longitude"));

  private static Instant instant(ResultSet rs, String column) throws SQLException {
    Timestamp value = rs.getTimestamp(column);
    return value == null ? null : value.toInstant();
  }
}
