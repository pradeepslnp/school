package com.guardian.guardian.infrastructure.persistence;

import com.guardian.guardian.application.port.CustodyRestrictionRepository;
import com.guardian.guardian.domain.CustodyRestriction;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code custody_restrictions} (MOD-04).
 *
 * <p>Runs under row-level security, so tenant scoping is absent from the SQL by design. No {@code
 * DELETE} — V4 grants none, and {@link #lift} deactivates instead.
 */
@Component
public class JdbcCustodyRestrictionRepository implements CustodyRestrictionRepository {

  private final JdbcTemplate jdbc;

  public JdbcCustodyRestrictionRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public List<CustodyRestriction> findAllForStudent(UUID studentId) {
    return jdbc.query(
        """
        SELECT id, student_id, restricted_guardian_id, restricted_person_name,
               restriction_type, reason, effective_from, effective_until, is_active
        FROM custody_restrictions
        WHERE student_id = ?
        ORDER BY created_at DESC
        """,
        MAPPER,
        studentId);
  }

  @Override
  public Optional<CustodyRestriction> findById(UUID id) {
    return jdbc
        .query(
            """
            SELECT id, student_id, restricted_guardian_id, restricted_person_name,
                   restriction_type, reason, effective_from, effective_until, is_active
            FROM custody_restrictions
            WHERE id = ?
            """,
            MAPPER,
            id)
        .stream()
        .findFirst();
  }

  @Override
  public CustodyRestriction save(CustodyRestriction restriction, UUID actorUserId) {
    UUID id =
        jdbc.queryForObject(
            """
            INSERT INTO custody_restrictions
                   (tenant_id, student_id, restricted_guardian_id, restricted_person_name,
                    restriction_type, reason, effective_from, effective_until, is_active,
                    created_by, updated_by)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, ?, ?, ?, true, ?, ?)
            RETURNING id
            """,
            UUID.class,
            restriction.studentId(),
            restriction.restrictedGuardianId(),
            restriction.restrictedPersonName(),
            restriction.type().name(),
            restriction.reason(),
            Timestamp.from(restriction.effectiveFrom()),
            restriction.effectiveUntil() == null
                ? null
                : Timestamp.from(restriction.effectiveUntil()),
            actorUserId,
            actorUserId);

    return new CustodyRestriction(
        id,
        restriction.studentId(),
        restriction.restrictedGuardianId(),
        restriction.restrictedPersonName(),
        restriction.type(),
        restriction.reason(),
        restriction.effectiveFrom(),
        restriction.effectiveUntil(),
        true);
  }

  @Override
  public void lift(UUID id, UUID actorUserId) {
    jdbc.update(
        """
        UPDATE custody_restrictions
           SET is_active = false, updated_at = now(), updated_by = ?, version = version + 1
         WHERE id = ? AND is_active
        """,
        actorUserId,
        id);
  }

  @Override
  public boolean guardianExists(UUID guardianId) {
    Boolean exists =
        jdbc.queryForObject(
            "SELECT EXISTS (SELECT 1 FROM guardians WHERE id = ? AND is_active)",
            Boolean.class,
            guardianId);
    return Boolean.TRUE.equals(exists);
  }

  private static final RowMapper<CustodyRestriction> MAPPER =
      (ResultSet rs, int rowNum) -> {
        Timestamp until = rs.getTimestamp("effective_until");
        return new CustodyRestriction(
            rs.getObject("id", UUID.class),
            rs.getObject("student_id", UUID.class),
            rs.getObject("restricted_guardian_id", UUID.class),
            rs.getString("restricted_person_name"),
            CustodyRestriction.Type.fromStored(rs.getString("restriction_type")),
            rs.getString("reason"),
            rs.getTimestamp("effective_from").toInstant(),
            until == null ? null : until.toInstant(),
            rs.getBoolean("is_active"));
      };
}
