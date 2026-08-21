package com.guardian.notification.infrastructure.persistence;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.guardian.notification.application.port.NotificationRepository;
import com.guardian.notification.domain.NotificationEntry;
import java.sql.ResultSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/** JDBC adapter for {@code notifications} (MOD-12). */
@Component
public class JdbcNotificationRepository implements NotificationRepository {

  private static final Logger log = LoggerFactory.getLogger(JdbcNotificationRepository.class);
  private static final TypeReference<Map<String, Object>> PARAMS =
      new TypeReference<Map<String, Object>>() {};

  private final JdbcTemplate jdbc;
  private final ObjectMapper objectMapper;

  public JdbcNotificationRepository(JdbcTemplate jdbc, ObjectMapper objectMapper) {
    this.jdbc = jdbc;
    this.objectMapper = objectMapper;
  }

  @Override
  public List<NotificationEntry> findForUser(UUID userId, int limit) {
    return jdbc.query(
        """
        SELECT n.id, n.catalog_id, n.priority, n.body_key, n.body_params, n.body_fallback,
               n.student_id, n.trip_id, n.occurred_at, n.read_at,
               s.first_name || ' ' || s.last_name AS student_display_name
        FROM notifications n
        -- Resolved through the recipient's OWN active guardian link, not from students
        -- directly. A notification row carries a student_id; joining on that alone would
        -- name a child for any recipient the row happened to reference. Routing the join
        -- through gsl means a name appears only where the reader is already entitled to it
        -- (BR-NTF-007).
        LEFT JOIN guardians g
               ON g.user_id = n.user_id AND g.is_active
        LEFT JOIN guardian_student_links gsl
               ON gsl.guardian_id = g.id AND gsl.student_id = n.student_id AND gsl.is_active
        LEFT JOIN students s
               ON s.id = gsl.student_id
        WHERE n.user_id = ?
        ORDER BY n.occurred_at DESC
        LIMIT ?
        """,
        mapper(),
        userId,
        limit);
  }

  @Override
  public boolean markRead(UUID userId, UUID notificationId) {
    // user_id is in the WHERE clause, not checked beforehand: one statement, no window between
    // the check and the write, and an id belonging to someone else simply updates nothing.
    int updated =
        jdbc.update(
            """
            UPDATE notifications
               SET read_at = now(), version = version + 1
             WHERE id = ? AND user_id = ? AND read_at IS NULL
            """,
            notificationId,
            userId);
    return updated > 0;
  }

  /**
   * The school behind this user's guardian link.
   *
   * <p>Reads MOD-03/04's tables, which crosses a module boundary — the same bounded exception
   * {@code JdbcAbsenceRepository.tripAlreadyStarted} takes, and for the same reason: the
   * alternative is MOD-12 depending on those modules' Java, which the module graph forbids. It is
   * one string, read-only, and confined to this method.
   *
   * <p>{@code LIMIT 1}: a guardian's children are at one school in every case the platform supports
   * today. If multi-school families arrive, this becomes a per-notification lookup rather than a
   * per-response one.
   */
  @Override
  public Optional<String> schoolTimezoneFor(UUID userId) {
    return jdbc
        .query(
            """
            SELECT sch.timezone
            FROM guardians g
            JOIN guardian_student_links gsl ON gsl.guardian_id = g.id AND gsl.is_active
            JOIN students s   ON s.id = gsl.student_id
            JOIN schools  sch ON sch.id = s.school_id
            WHERE g.user_id = ? AND g.is_active
            LIMIT 1
            """,
            (ResultSet rs, int rowNum) -> rs.getString("timezone"),
            userId)
        .stream()
        .findFirst();
  }

  private RowMapper<NotificationEntry> mapper() {
    return (ResultSet rs, int rowNum) ->
        new NotificationEntry(
            rs.getObject("id", UUID.class),
            rs.getString("catalog_id"),
            NotificationEntry.Priority.valueOf(rs.getString("priority")),
            rs.getString("body_key"),
            readParams(rs.getString("body_params")),
            rs.getString("body_fallback"),
            rs.getObject("student_id", UUID.class),
            rs.getString("student_display_name"),
            rs.getObject("trip_id", UUID.class),
            rs.getTimestamp("occurred_at").toInstant(),
            rs.getTimestamp("read_at") == null ? null : rs.getTimestamp("read_at").toInstant());
  }

  /**
   * Decodes {@code body_params}, degrading to empty rather than failing the whole list.
   *
   * <p>These are template variables. One unreadable row should cost the parent that row's
   * substitutions — the fallback copy still renders — not the entire notification centre.
   */
  private Map<String, Object> readParams(String json) {
    if (json == null || json.isBlank()) {
      return Map.of();
    }
    try {
      return objectMapper.readValue(json, PARAMS);
    } catch (Exception e) {
      log.warn("Unreadable notification body_params; rendering without substitutions", e);
      return Map.of();
    }
  }
}
