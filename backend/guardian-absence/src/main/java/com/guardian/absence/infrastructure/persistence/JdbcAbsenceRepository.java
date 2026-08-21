package com.guardian.absence.infrastructure.persistence;

import com.guardian.absence.application.port.AbsenceRepository;
import com.guardian.absence.domain.Absence;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code absences} (MOD-14).
 *
 * <p>JDBC rather than JPA: this module has one small table and two of its four queries are checks
 * that return a single boolean. A JPA aggregate here would be ceremony around four statements.
 *
 * <p>Every statement runs under row-level security, so tenant scoping is not repeated in the SQL —
 * adding {@code AND tenant_id = ?} would suggest the policy is optional.
 */
@Component
public class JdbcAbsenceRepository implements AbsenceRepository {

  private final JdbcTemplate jdbc;

  public JdbcAbsenceRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public Absence save(Absence absence, UUID actorUserId) {
    UUID id =
        jdbc.queryForObject(
            """
            INSERT INTO absences (tenant_id, student_id, declared_by_guardian_id,
                                  from_date, to_date, direction, reason, status,
                                  created_by, updated_by)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, ?)
            RETURNING id
            """,
            UUID.class,
            absence.studentId(),
            absence.declaredByGuardianId(),
            absence.fromDate(),
            absence.toDate(),
            absence.direction() == null ? null : absence.direction().name(),
            absence.reason(),
            actorUserId,
            actorUserId);

    return new Absence(
        id,
        absence.studentId(),
        absence.declaredByGuardianId(),
        absence.fromDate(),
        absence.toDate(),
        absence.direction(),
        absence.reason(),
        Absence.Status.ACTIVE);
  }

  @Override
  public List<Absence> findActiveForStudent(UUID studentId) {
    return jdbc.query(
        """
        SELECT id, student_id, declared_by_guardian_id, from_date, to_date,
               direction, reason, status
        FROM absences
        WHERE student_id = ? AND status = 'ACTIVE'
        ORDER BY from_date
        """,
        MAPPER,
        studentId);
  }

  @Override
  public Optional<Absence> findById(UUID absenceId) {
    return jdbc
        .query(
            """
            SELECT id, student_id, declared_by_guardian_id, from_date, to_date,
                   direction, reason, status
            FROM absences
            WHERE id = ?
            """,
            MAPPER,
            absenceId)
        .stream()
        .findFirst();
  }

  @Override
  public void cancel(UUID absenceId, UUID actorUserId) {
    // An UPDATE, not a DELETE — and the grant in V6 gives no DELETE, so this is the only shape
    // the database would accept even if this method wanted another.
    jdbc.update(
        """
        UPDATE absences
           SET status = 'CANCELLED', cancelled_at = now(), cancelled_by = ?,
               updated_at = now(), updated_by = ?, version = version + 1
         WHERE id = ? AND status = 'ACTIVE'
        """,
        actorUserId,
        actorUserId,
        absenceId);
  }

  /**
   * BR-ABS-003. True when a trip carrying this student on this date and run has left.
   *
   * <p>Reads MOD-08's tables directly, which is the one thing this module does that crosses a
   * boundary. It is a single boolean rather than a dependency on the trip module's Java, and the
   * alternative — MOD-14 depending on MOD-08 — is the upward edge the module graph forbids.
   */
  @Override
  public boolean tripAlreadyStarted(UUID studentId, LocalDate date, Absence.Direction direction) {
    Boolean started =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1
                FROM route_student_assignments rsa
                JOIN trips t ON t.route_id = rsa.route_id
                            AND t.direction = rsa.direction
                            AND t.service_date = ?
                WHERE rsa.student_id = ?
                  AND rsa.is_active
                  AND rsa.direction = ?
                  AND t.started_at IS NOT NULL
                  AND t.status <> 'CANCELLED')
            """,
            Boolean.class,
            date,
            studentId,
            direction.name());
    return Boolean.TRUE.equals(started);
  }

  /**
   * The guardian id for this user on this student, only when they hold {@code can_declare_absence}.
   *
   * <p>Returning the id rather than a boolean is deliberate: the caller needs it to record who
   * declared the absence, and asking twice would be two chances for the two answers to disagree.
   */
  @Override
  public Optional<UUID> declaringGuardianIdFor(UUID userId, UUID studentId) {
    return jdbc
        .query(
            """
            SELECT g.id
            FROM guardian_student_links gsl
            JOIN guardians g ON g.id = gsl.guardian_id AND g.is_active
            WHERE g.user_id = ?
              AND gsl.student_id = ?
              AND gsl.is_active
              AND gsl.can_declare_absence
            """,
            (ResultSet rs, int rowNum) -> rs.getObject("id", UUID.class),
            userId,
            studentId)
        .stream()
        .findFirst();
  }

  private static final RowMapper<Absence> MAPPER =
      (ResultSet rs, int rowNum) ->
          new Absence(
              rs.getObject("id", UUID.class),
              rs.getObject("student_id", UUID.class),
              rs.getObject("declared_by_guardian_id", UUID.class),
              rs.getObject("from_date", LocalDate.class),
              rs.getObject("to_date", LocalDate.class),
              direction(rs.getString("direction")),
              rs.getString("reason"),
              Absence.Status.valueOf(rs.getString("status")));

  private static Absence.Direction direction(String wire) {
    // NULL means both journeys, which the domain models as a null Direction.
    return wire == null ? null : Absence.Direction.valueOf(wire);
  }
}
