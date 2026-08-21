package com.guardian.guardian.infrastructure.persistence;

import com.guardian.guardian.application.port.PickupPersonRepository;
import com.guardian.guardian.domain.PickupPerson;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code authorised_pickup_persons} and the guardian-link rights that gate it
 * (MOD-04).
 *
 * <p>Runs under row-level security like everything else, so tenant scoping is absent from the SQL
 * by design — repeating it would imply the policy were optional.
 */
@Component
public class JdbcPickupPersonRepository implements PickupPersonRepository {

  private final JdbcTemplate jdbc;

  public JdbcPickupPersonRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public List<PickupPerson> findActiveForStudent(UUID studentId) {
    return jdbc.query(
        """
        SELECT id, student_id, nominated_by_guardian_id, full_name, phone,
               relationship_note, valid_from, valid_until, is_active
        FROM authorised_pickup_persons
        WHERE student_id = ? AND is_active
        ORDER BY valid_until
        """,
        MAPPER,
        studentId);
  }

  @Override
  public PickupPerson save(PickupPerson person, UUID actorUserId) {
    UUID id =
        jdbc.queryForObject(
            """
            INSERT INTO authorised_pickup_persons
                   (tenant_id, student_id, nominated_by_guardian_id, full_name, phone,
                    relationship_note, valid_from, valid_until, is_active, created_by, updated_by)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, ?, ?, ?, true, ?, ?)
            RETURNING id
            """,
            UUID.class,
            person.studentId(),
            person.nominatedByGuardianId(),
            person.fullName(),
            person.phone(),
            person.relationshipNote(),
            Timestamp.from(person.validFrom()),
            Timestamp.from(person.validUntil()),
            actorUserId,
            actorUserId);

    return new PickupPerson(
        id,
        person.studentId(),
        person.nominatedByGuardianId(),
        person.fullName(),
        person.phone(),
        person.relationshipNote(),
        person.validFrom(),
        person.validUntil(),
        true);
  }

  @Override
  public void revoke(UUID pickupPersonId, UUID actorUserId) {
    // is_active goes false and the row stays. V4 grants no DELETE on this table, so the record
    // survives even a caller who wanted otherwise.
    jdbc.update(
        """
        UPDATE authorised_pickup_persons
           SET is_active = false, revoked_at = now(), revoked_by = ?,
               updated_at = now(), updated_by = ?, version = version + 1
         WHERE id = ? AND is_active
        """,
        actorUserId,
        actorUserId,
        pickupPersonId);
  }

  @Override
  public Optional<PickupPerson> findById(UUID pickupPersonId) {
    return jdbc
        .query(
            """
            SELECT id, student_id, nominated_by_guardian_id, full_name, phone,
                   relationship_note, valid_from, valid_until, is_active
            FROM authorised_pickup_persons
            WHERE id = ?
            """,
            MAPPER,
            pickupPersonId)
        .stream()
        .findFirst();
  }

  /** BR-GRD-006 as a lookup: the link must be active and carry {@code can_authorise_handover}. */
  @Override
  public Optional<UUID> nominatingGuardianIdFor(UUID userId, UUID studentId) {
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

  @Override
  public boolean isLinkedGuardian(UUID userId, UUID studentId) {
    Boolean linked =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1
                FROM guardian_student_links gsl
                JOIN guardians g ON g.id = gsl.guardian_id AND g.is_active
                WHERE g.user_id = ? AND gsl.student_id = ? AND gsl.is_active AND gsl.can_view)
            """,
            Boolean.class,
            userId,
            studentId);
    return Boolean.TRUE.equals(linked);
  }

  private static final RowMapper<PickupPerson> MAPPER =
      (ResultSet rs, int rowNum) ->
          new PickupPerson(
              rs.getObject("id", UUID.class),
              rs.getObject("student_id", UUID.class),
              rs.getObject("nominated_by_guardian_id", UUID.class),
              rs.getString("full_name"),
              rs.getString("phone"),
              rs.getString("relationship_note"),
              rs.getTimestamp("valid_from").toInstant(),
              rs.getTimestamp("valid_until").toInstant(),
              rs.getBoolean("is_active"));
}
