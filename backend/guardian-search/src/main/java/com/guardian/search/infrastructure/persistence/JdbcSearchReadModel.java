package com.guardian.search.infrastructure.persistence;

import com.guardian.common.security.AccessScope;
import com.guardian.search.application.port.SearchReadModel;
import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Global search's cross-module projection — the whole of the coupling ADR-0017 accepts, in one
 * file.
 *
 * <p>It reads tables owned by MOD-01 (schools, organizations), MOD-02 (users, roles, scopes),
 * MOD-03 (students), MOD-04 (guardians and their links), MOD-05 (vehicles), MOD-06 (transport
 * staff) and MOD-07 (routes). That is the same bounded exception to "a module owns its tables"
 * argued in ADR-0010, contained here rather than spread across the module.
 *
 * <p><strong>Load-bearing properties.</strong>
 *
 * <ul>
 *   <li><em>Scope lives in the WHERE clause.</em> Every school-bound query carries {@code (? OR
 *       school_id = ANY(?))}, bound from the caller's resolved scope (BR-IAM-006). A record outside
 *       it is never read.
 *   <li><em>Row-level security still applies to every statement</em> — this relaxes module
 *       boundaries, never tenant boundaries.
 *   <li><em>Plain {@code LIKE}, no index.</em> Queries scan one tenant's rows, which is thousands,
 *       not millions. ADR-0017 names the trigger for trigram indexes or a search index behind this
 *       same port.
 * </ul>
 *
 * <p>Rows are turned into results by {@link SearchRows}, shared with the platform-wide projection
 * ({@link JdbcPlatformSearchReadModel}, ADR-0018).
 */
@Component
public class JdbcSearchReadModel implements SearchReadModel {

  /** Parameters: organization-wide, school ids, name, admission number, rank, limit. */
  private static final String STUDENTS_SQL =
      """
      SELECT s.id, s.first_name, s.last_name, s.admission_no, s.enrolment_status,
             s.school_id, sch.name AS school_name
      FROM students s
      JOIN schools sch ON sch.id = s.school_id
      WHERE (? OR s.school_id = ANY(?))
        AND (lower(s.first_name || ' ' || s.last_name) LIKE ?
             OR lower(s.admission_no) LIKE ?)
      ORDER BY lower(s.first_name || ' ' || s.last_name) LIKE ? DESC,
               s.first_name, s.last_name, s.id
      LIMIT ?
      """;

  /**
   * Parameters: organization-wide, school ids (both inside the child lookup), name, phone digits,
   * email, rank, limit.
   *
   * <p>A guardian is visible through a child: the lateral join keeps only guardians actively linked
   * to a student within scope, and carries that child — the primary link first — as the context the
   * console shows beside them.
   */
  private static final String GUARDIANS_SQL =
      """
      SELECT g.id, g.first_name, g.last_name, g.phone, g.email, g.is_active,
             child.student_id, child.student_name, child.school_id, child.school_name
      FROM guardians g
      JOIN LATERAL (
          SELECT s.id AS student_id,
                 s.first_name || ' ' || s.last_name AS student_name,
                 s.school_id,
                 sch.name AS school_name
          FROM guardian_student_links l
          JOIN students s   ON s.id = l.student_id
          JOIN schools  sch ON sch.id = s.school_id
          WHERE l.guardian_id = g.id
            AND l.is_active
            AND (? OR s.school_id = ANY(?))
          ORDER BY l.is_primary DESC, s.first_name, s.last_name
          LIMIT 1
      ) child ON TRUE
      WHERE lower(g.first_name || ' ' || g.last_name) LIKE ?
         OR regexp_replace(g.phone, '[^0-9]', '', 'g') LIKE COALESCE(CAST(? AS text), '')
         OR lower(g.email) LIKE ?
      ORDER BY lower(g.first_name || ' ' || g.last_name) LIKE ? DESC,
               g.first_name, g.last_name, g.id
      LIMIT ?
      """;

  /** Parameters: organization-wide, school ids, name, phone digits, employee code, rank, limit. */
  private static final String STAFF_SQL =
      """
      SELECT t.id, t.first_name, t.last_name, t.staff_type, t.phone, t.employee_code,
             t.is_active, t.school_id, sch.name AS school_name
      FROM transport_staff t
      JOIN schools sch ON sch.id = t.school_id
      WHERE (? OR t.school_id = ANY(?))
        AND (lower(t.first_name || ' ' || t.last_name) LIKE ?
             OR regexp_replace(t.phone, '[^0-9]', '', 'g') LIKE COALESCE(CAST(? AS text), '')
             OR lower(t.employee_code) LIKE ?)
      ORDER BY lower(t.first_name || ' ' || t.last_name) LIKE ? DESC,
               t.first_name, t.last_name, t.id
      LIMIT ?
      """;

  /**
   * Parameters: organization-wide, school ids, display name, registration, registration letters and
   * digits only, rank, limit.
   */
  private static final String VEHICLES_SQL =
      """
      SELECT v.id, v.display_name, v.registration_no, v.vehicle_type, v.status,
             v.school_id, sch.name AS school_name
      FROM vehicles v
      JOIN schools sch ON sch.id = v.school_id
      WHERE (? OR v.school_id = ANY(?))
        AND (lower(v.display_name) LIKE ?
             OR lower(v.registration_no) LIKE ?
             OR regexp_replace(lower(v.registration_no), '[^[:alnum:]]', '', 'g') LIKE ?)
      ORDER BY lower(v.display_name) LIKE ? DESC, v.display_name, v.id
      LIMIT ?
      """;

  /** Parameters: organization-wide, school ids, name, code, rank, limit. */
  private static final String ROUTES_SQL =
      """
      SELECT r.id, r.name, r.code, r.school_id, sch.name AS school_name
      FROM routes r
      JOIN schools sch ON sch.id = r.school_id
      WHERE (? OR r.school_id = ANY(?))
        AND (lower(r.name) LIKE ? OR lower(r.code) LIKE ?)
      ORDER BY lower(r.name) LIKE ? DESC, r.name, r.id
      LIMIT ?
      """;

  /** Parameters: organization-wide, school ids, name, code, rank, limit. */
  private static final String SCHOOLS_SQL =
      """
      SELECT sch.id, sch.name, sch.code, sch.status
      FROM schools sch
      WHERE (? OR sch.id = ANY(?))
        AND (lower(sch.name) LIKE ? OR lower(sch.code) LIKE ?)
      ORDER BY lower(sch.name) LIKE ? DESC, sch.name, sch.id
      LIMIT ?
      """;

  /**
   * Parameters: organization-wide, school ids, name, email, phone digits, rank, limit.
   *
   * <p>"Administrative" is the Users screen's own definition ({@code
   * UserJpaRepository.findAdministrativeUsers}): accounts holding ORG_ADMIN, SCHOOL_ADMIN,
   * PRINCIPAL or TRANSPORT_MANAGER. Guardians and transport staff are searched as themselves,
   * above. A school-scoped caller sees only accounts whose current scope is one of their schools.
   */
  private static final String USERS_SQL =
      """
      SELECT u.id, u.first_name, u.last_name, u.email, u.phone, u.status,
             ar.code AS role_code,
             CASE WHEN cs.scope_level = 'SCHOOL' THEN cs.scope_ref_id END AS school_id,
             sch.name AS school_name
      FROM users u
      JOIN LATERAL (
          SELECT r.code
          FROM user_roles ur
          JOIN roles r ON r.id = ur.role_id
          WHERE ur.user_id = u.id
            AND r.code IN ('ORG_ADMIN', 'SCHOOL_ADMIN', 'PRINCIPAL', 'TRANSPORT_MANAGER')
          ORDER BY ur.created_at DESC
          LIMIT 1
      ) ar ON TRUE
      LEFT JOIN LATERAL (
          SELECT us.scope_level, us.scope_ref_id
          FROM user_scopes us
          WHERE us.user_id = u.id
          ORDER BY us.created_at DESC
          LIMIT 1
      ) cs ON TRUE
      LEFT JOIN schools sch ON sch.id = cs.scope_ref_id AND cs.scope_level = 'SCHOOL'
      WHERE (? OR (cs.scope_level = 'SCHOOL' AND cs.scope_ref_id = ANY(?)))
        AND (lower(u.first_name || ' ' || u.last_name) LIKE ?
             OR lower(u.email) LIKE ?
             OR regexp_replace(u.phone, '[^0-9]', '', 'g') LIKE COALESCE(CAST(? AS text), ''))
      ORDER BY lower(u.first_name || ' ' || u.last_name) LIKE ? DESC,
               u.first_name, u.last_name, u.id
      LIMIT ?
      """;

  /** Parameters: name, code, limit. Row-level security returns only the acting organization. */
  private static final String OWN_ORGANIZATION_SQL =
      """
      SELECT o.id, o.name, o.code, o.region_profile_code, o.status
      FROM organizations o
      WHERE lower(o.name) LIKE ? OR lower(o.code) LIKE ?
      ORDER BY o.name, o.id
      LIMIT ?
      """;

  private final JdbcTemplate jdbc;

  public JdbcSearchReadModel(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public List<SearchHit> students(SearchQuery query, AccessScope scope, int limit) {
    return SearchRows.query(
        jdbc,
        STUDENTS_SQL,
        SearchRows.students(query, false),
        scope.organizationWide(),
        scope.schoolIds(),
        query.containsPattern(),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> guardians(SearchQuery query, AccessScope scope, int limit) {
    return SearchRows.query(
        jdbc,
        GUARDIANS_SQL,
        SearchRows.guardians(query, false),
        scope.organizationWide(),
        scope.schoolIds(),
        query.containsPattern(),
        query.digitsPattern(),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> staff(SearchQuery query, AccessScope scope, int limit) {
    return SearchRows.query(
        jdbc,
        STAFF_SQL,
        SearchRows.staff(query, false),
        scope.organizationWide(),
        scope.schoolIds(),
        query.containsPattern(),
        query.digitsPattern(),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> vehicles(SearchQuery query, AccessScope scope, int limit) {
    return SearchRows.query(
        jdbc,
        VEHICLES_SQL,
        SearchRows.vehicles(query, false),
        scope.organizationWide(),
        scope.schoolIds(),
        query.containsPattern(),
        query.containsPattern(),
        query.alphanumericPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> routes(SearchQuery query, AccessScope scope, int limit) {
    return SearchRows.query(
        jdbc,
        ROUTES_SQL,
        SearchRows.routes(query, false),
        scope.organizationWide(),
        scope.schoolIds(),
        query.containsPattern(),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> schools(SearchQuery query, AccessScope scope, int limit) {
    return SearchRows.query(
        jdbc,
        SCHOOLS_SQL,
        SearchRows.schools(query, false),
        scope.organizationWide(),
        scope.schoolIds(),
        query.containsPattern(),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> administrativeUsers(SearchQuery query, AccessScope scope, int limit) {
    return SearchRows.query(
        jdbc,
        USERS_SQL,
        SearchRows.administrativeUsers(query, false),
        scope.organizationWide(),
        scope.schoolIds(),
        query.containsPattern(),
        query.containsPattern(),
        query.digitsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> ownOrganization(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        OWN_ORGANIZATION_SQL,
        SearchRows.organizations(query),
        query.containsPattern(),
        query.containsPattern(),
        limit);
  }
}
