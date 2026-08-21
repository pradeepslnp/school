package com.guardian.boarding.infrastructure.persistence;

import com.guardian.boarding.application.port.HandoverCodeRepository;
import com.guardian.boarding.domain.HandoverCode;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code handover_verification_codes} (MOD-09).
 *
 * <p>JDBC rather than JPA, same reasoning as {@code JdbcAbsenceRepository}: one small table, two
 * statements. Runs under row-level security, so tenant scoping is absent from the SQL by design.
 */
@Component
public class JdbcHandoverCodeRepository implements HandoverCodeRepository {

  private final JdbcTemplate jdbc;

  public JdbcHandoverCodeRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public HandoverCode issue(HandoverCode code, UUID actorUserId) {
    // Superseded before the new row exists, not after: a query that lands between the two
    // statements should never see two live codes for the same student.
    jdbc.update(
        """
        UPDATE handover_verification_codes
           SET superseded_at = now()
         WHERE student_id = ?
           AND superseded_at IS NULL
           AND redeemed_at IS NULL
           AND expires_at > now()
        """,
        code.studentId());

    UUID id =
        jdbc.queryForObject(
            """
            INSERT INTO handover_verification_codes
                   (tenant_id, student_id, requested_by_guardian_id, code,
                    issued_at, expires_at, created_by)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, ?, ?)
            RETURNING id
            """,
            UUID.class,
            code.studentId(),
            code.requestedByGuardianId(),
            code.code(),
            Timestamp.from(code.issuedAt()),
            Timestamp.from(code.expiresAt()),
            actorUserId);

    return new HandoverCode(
        id,
        code.studentId(),
        code.requestedByGuardianId(),
        code.code(),
        code.issuedAt(),
        code.expiresAt());
  }

  /** BR-GRD-006 as a lookup, identical shape to MOD-04's nominatingGuardianIdFor. */
  @Override
  public Optional<UUID> authorisingGuardianIdFor(UUID userId, UUID studentId) {
    return jdbc
        .query(
            """
            SELECT g.id
            FROM guardian_student_links gsl
            JOIN guardians g ON g.id = gsl.guardian_id AND g.is_active
            WHERE g.user_id = ?
              AND gsl.student_id = ?
              AND gsl.is_active
              AND gsl.can_authorise_handover
            """,
            (ResultSet rs, int rowNum) -> rs.getObject("id", UUID.class),
            userId,
            studentId)
        .stream()
        .findFirst();
  }
}
