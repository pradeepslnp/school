package com.guardian.guardian.infrastructure.persistence;

import com.guardian.guardian.application.port.GuardianRepository;
import com.guardian.guardian.domain.Guardian;
import com.guardian.guardian.domain.GuardianStudentLink;
import java.sql.ResultSet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * JDBC adapter for {@code guardians} and {@code guardian_student_links} (MOD-04).
 *
 * <p>Runs under row-level security like everything else, so tenant scoping is absent from the SQL
 * by design — repeating it would imply the policy were optional. The {@code tenant_id} written on
 * insert comes from the session setting the RLS policy itself reads, matching {@code
 * JdbcPickupPersonRepository}.
 */
@Component
public class JdbcGuardianRepository implements GuardianRepository {

  private final JdbcTemplate jdbc;

  public JdbcGuardianRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public Optional<Guardian> findByUserId(UUID userId) {
    return jdbc
        .query(
            """
            SELECT id, user_id, first_name, last_name, phone, email, is_active
            FROM guardians
            WHERE user_id = ? AND is_active
            """,
            GUARDIAN_MAPPER,
            userId)
        .stream()
        .findFirst();
  }

  @Override
  public Optional<Guardian> findById(UUID guardianId) {
    return jdbc
        .query(
            """
            SELECT id, user_id, first_name, last_name, phone, email, is_active
            FROM guardians
            WHERE id = ?
            """,
            GUARDIAN_MAPPER,
            guardianId)
        .stream()
        .findFirst();
  }

  @Override
  public boolean existsByUserIdExcluding(UUID userId, UUID excludingGuardianId) {
    Boolean exists =
        jdbc.queryForObject(
            "SELECT EXISTS (SELECT 1 FROM guardians WHERE user_id = ? AND id <> ?)",
            Boolean.class,
            userId,
            excludingGuardianId);
    return Boolean.TRUE.equals(exists);
  }

  @Override
  public Guardian saveGuardian(Guardian guardian, UUID actorUserId) {
    UUID id =
        jdbc.queryForObject(
            """
            INSERT INTO guardians
                   (tenant_id, user_id, first_name, last_name, phone, email,
                    is_active, created_by, updated_by)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, ?, true, ?, ?)
            RETURNING id
            """,
            UUID.class,
            guardian.userId(),
            guardian.firstName(),
            guardian.lastName(),
            guardian.phone(),
            guardian.email(),
            actorUserId,
            actorUserId);

    return new Guardian(
        id,
        guardian.userId(),
        guardian.firstName(),
        guardian.lastName(),
        guardian.phone(),
        guardian.email(),
        true);
  }

  @Override
  public Guardian updateGuardian(Guardian guardian, UUID actorUserId) {
    jdbc.update(
        """
        UPDATE guardians
           SET user_id = ?, first_name = ?, last_name = ?, phone = ?, email = ?,
               updated_at = now(), updated_by = ?, version = version + 1
         WHERE id = ?
        """,
        guardian.userId(),
        guardian.firstName(),
        guardian.lastName(),
        guardian.phone(),
        guardian.email(),
        actorUserId,
        guardian.id());
    return guardian;
  }

  @Override
  public GuardianStudentLink saveLink(GuardianStudentLink link, UUID actorUserId) {
    // ON CONFLICT reactivates and updates an existing link for the same (guardian, student) pair
    // rather than failing on uq_guardian_student — re-adding a parent who was removed, or changing
    // their rights, is the same operation as adding them.
    UUID id =
        jdbc.queryForObject(
            """
            INSERT INTO guardian_student_links
                   (tenant_id, guardian_id, student_id, relationship_type,
                    can_view, can_receive_notifications, can_authorise_handover,
                    can_declare_absence, is_primary, is_active, created_by, updated_by)
            VALUES (NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                    ?, ?, ?, ?, ?, ?, ?, ?, true, ?, ?)
            ON CONFLICT (tenant_id, guardian_id, student_id) DO UPDATE SET
                    relationship_type = EXCLUDED.relationship_type,
                    can_view = EXCLUDED.can_view,
                    can_receive_notifications = EXCLUDED.can_receive_notifications,
                    can_authorise_handover = EXCLUDED.can_authorise_handover,
                    can_declare_absence = EXCLUDED.can_declare_absence,
                    is_primary = EXCLUDED.is_primary,
                    is_active = true,
                    updated_at = now(),
                    updated_by = EXCLUDED.updated_by,
                    version = guardian_student_links.version + 1
            RETURNING id
            """,
            UUID.class,
            link.guardianId(),
            link.studentId(),
            link.relationshipType(),
            link.canView(),
            link.canReceiveNotifications(),
            link.canAuthoriseHandover(),
            link.canDeclareAbsence(),
            link.isPrimary(),
            actorUserId,
            actorUserId);

    return new GuardianStudentLink(
        id,
        link.guardianId(),
        link.studentId(),
        link.relationshipType(),
        link.canView(),
        link.canReceiveNotifications(),
        link.canAuthoriseHandover(),
        link.canDeclareAbsence(),
        link.isPrimary(),
        true);
  }

  @Override
  public List<StudentGuardian> findActiveForStudent(UUID studentId) {
    return jdbc.query(
        """
        SELECT gsl.id AS link_id, g.id AS guardian_id, g.user_id,
               g.first_name, g.last_name, g.phone, g.email,
               gsl.relationship_type, gsl.can_view, gsl.can_receive_notifications,
               gsl.can_authorise_handover, gsl.can_declare_absence, gsl.is_primary
        FROM guardian_student_links gsl
        JOIN guardians g ON g.id = gsl.guardian_id AND g.is_active
        WHERE gsl.student_id = ? AND gsl.is_active
        ORDER BY gsl.is_primary DESC, g.first_name, g.last_name
        """,
        STUDENT_GUARDIAN_MAPPER,
        studentId);
  }

  @Override
  public boolean hasActiveHandoverGuardian(UUID studentId) {
    Boolean exists =
        jdbc.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1
                FROM guardian_student_links gsl
                JOIN guardians g ON g.id = gsl.guardian_id AND g.is_active
                WHERE gsl.student_id = ? AND gsl.is_active AND gsl.can_authorise_handover)
            """,
            Boolean.class,
            studentId);
    return Boolean.TRUE.equals(exists);
  }

  @Override
  public int deleteLinksForStudent(UUID studentId) {
    return jdbc.update("DELETE FROM guardian_student_links WHERE student_id = ?", studentId);
  }

  private static final RowMapper<Guardian> GUARDIAN_MAPPER =
      (ResultSet rs, int rowNum) ->
          new Guardian(
              rs.getObject("id", UUID.class),
              rs.getObject("user_id", UUID.class),
              rs.getString("first_name"),
              rs.getString("last_name"),
              rs.getString("phone"),
              rs.getString("email"),
              rs.getBoolean("is_active"));

  private static final RowMapper<StudentGuardian> STUDENT_GUARDIAN_MAPPER =
      (ResultSet rs, int rowNum) ->
          new StudentGuardian(
              rs.getObject("link_id", UUID.class),
              rs.getObject("guardian_id", UUID.class),
              rs.getObject("user_id", UUID.class),
              rs.getString("first_name"),
              rs.getString("last_name"),
              rs.getString("phone"),
              rs.getString("email"),
              rs.getString("relationship_type"),
              rs.getBoolean("can_view"),
              rs.getBoolean("can_receive_notifications"),
              rs.getBoolean("can_authorise_handover"),
              rs.getBoolean("can_declare_absence"),
              rs.getBoolean("is_primary"));
}
