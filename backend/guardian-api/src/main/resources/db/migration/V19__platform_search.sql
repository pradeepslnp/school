-- V19 — Platform-wide search for platform operators (MOD-19, feature SRC-001, ADR-0018)
--
-- See docs/00-governance/adr/ADR-0018-platform-wide-search.md and docs/04-api/SEARCH_API.md.
--
-- ADR-0017's search is tenant-scoped: row-level security confines every statement to the
-- organization a request acts in. A platform operator asked for one search across every
-- organization, which no RLS-bound statement can answer. This migration adds that path the way V12
-- added the organizations list: SECURITY DEFINER functions owned by guardian_platform_ops
-- (NOLOGIN, BYPASSRLS), executable by guardian_app, and nothing more.
--
-- Each function is a hole in row-level security by design, so each is bounded:
--
--   * Read-only, fixed projections. Exactly the columns a search result needs; the caller names no
--     table, column, or predicate.
--   * Refuses a short pattern. Fewer than 3 characters besides wildcards returns nothing, so these
--     cannot become a bulk export even from code that bypasses SearchQuery.
--   * Capped at 26 rows per call, whatever limit is passed.
--   * One caller. RunPlatformSearchUseCase, reached only with a PLATFORM scope held by a
--     SUPER_ADMIN, which writes an audit record into every organization whose records it shows
--     and a data-access record for every student (BR-TEN-004, BR-AUD-005, BR-IAM-012).
--
-- guardian_app still holds no BYPASSRLS and owns no tables (ADR-0001, MULTI_TENANCY.md invariant 4).
--
-- Trigram indexes: a search across every tenant cannot use tenant_id-leading indexes, and a
-- substring scan over every organization's students does not survive thousands of schools.
-- pg_trgm GIN indexes serve LIKE '%…%' for patterns of 3+ characters — the minimum SearchQuery
-- enforces — and serve the tenant-scoped search too. pg_trgm is a trusted extension (PostgreSQL
-- 13+), available on managed PostgreSQL.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------------------
-- Read grants for the function owner. BYPASSRLS skips policies, not privileges.
-- ---------------------------------------------------------------------------------------
GRANT SELECT ON students, schools, guardians, guardian_student_links, transport_staff, vehicles,
    routes, users, user_roles, roles, user_scopes TO guardian_platform_ops;

-- ---------------------------------------------------------------------------------------
-- Search functions — one per kind of record, matching JdbcSearchReadModel's tenant-scoped SQL
-- column for column, plus the organization each row belongs to.
-- ---------------------------------------------------------------------------------------
CREATE FUNCTION platform_search_students(p_contains text, p_prefix text, p_limit integer)
    RETURNS TABLE (id uuid, organization_id uuid, organization_name varchar,
                   first_name varchar, last_name varchar, admission_no varchar,
                   enrolment_status varchar, school_id uuid, school_name varchar)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT s.id, s.tenant_id, o.name, s.first_name, s.last_name, s.admission_no,
           s.enrolment_status, s.school_id, sch.name
    FROM students s
    JOIN schools sch      ON sch.id = s.school_id
    JOIN organizations o  ON o.id = s.tenant_id
    WHERE length(replace(p_contains, '%', '')) >= 3
      AND (lower(s.first_name || ' ' || s.last_name) LIKE p_contains
           OR lower(s.admission_no) LIKE p_contains)
    ORDER BY lower(s.first_name || ' ' || s.last_name) LIKE p_prefix DESC,
             s.first_name, s.last_name, s.id
    LIMIT LEAST(GREATEST(p_limit, 0), 26)
$$;

CREATE FUNCTION platform_search_guardians(p_contains text, p_digits text, p_prefix text, p_limit integer)
    RETURNS TABLE (id uuid, organization_id uuid, organization_name varchar,
                   first_name varchar, last_name varchar, phone varchar, email varchar,
                   is_active boolean, student_id uuid, student_name text,
                   school_id uuid, school_name varchar)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT g.id, g.tenant_id, o.name, g.first_name, g.last_name, g.phone, g.email, g.is_active,
           child.student_id, child.student_name, child.school_id, child.school_name
    FROM guardians g
    JOIN organizations o ON o.id = g.tenant_id
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
        ORDER BY l.is_primary DESC, s.first_name, s.last_name
        LIMIT 1
    ) child ON TRUE
    WHERE length(replace(p_contains, '%', '')) >= 3
      AND (lower(g.first_name || ' ' || g.last_name) LIKE p_contains
           OR regexp_replace(g.phone, '[^0-9]', '', 'g') LIKE COALESCE(p_digits, '')
           OR lower(g.email) LIKE p_contains)
    ORDER BY lower(g.first_name || ' ' || g.last_name) LIKE p_prefix DESC,
             g.first_name, g.last_name, g.id
    LIMIT LEAST(GREATEST(p_limit, 0), 26)
$$;

CREATE FUNCTION platform_search_staff(p_contains text, p_digits text, p_prefix text, p_limit integer)
    RETURNS TABLE (id uuid, organization_id uuid, organization_name varchar,
                   first_name varchar, last_name varchar, staff_type varchar, phone varchar,
                   employee_code varchar, is_active boolean, school_id uuid, school_name varchar)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT t.id, t.tenant_id, o.name, t.first_name, t.last_name, t.staff_type, t.phone,
           t.employee_code, t.is_active, t.school_id, sch.name
    FROM transport_staff t
    JOIN schools sch     ON sch.id = t.school_id
    JOIN organizations o ON o.id = t.tenant_id
    WHERE length(replace(p_contains, '%', '')) >= 3
      AND (lower(t.first_name || ' ' || t.last_name) LIKE p_contains
           OR regexp_replace(t.phone, '[^0-9]', '', 'g') LIKE COALESCE(p_digits, '')
           OR lower(t.employee_code) LIKE p_contains)
    ORDER BY lower(t.first_name || ' ' || t.last_name) LIKE p_prefix DESC,
             t.first_name, t.last_name, t.id
    LIMIT LEAST(GREATEST(p_limit, 0), 26)
$$;

CREATE FUNCTION platform_search_vehicles(p_contains text, p_alphanumeric text, p_prefix text, p_limit integer)
    RETURNS TABLE (id uuid, organization_id uuid, organization_name varchar,
                   display_name varchar, registration_no varchar, vehicle_type varchar,
                   status varchar, school_id uuid, school_name varchar)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT v.id, v.tenant_id, o.name, v.display_name, v.registration_no, v.vehicle_type,
           v.status, v.school_id, sch.name
    FROM vehicles v
    JOIN schools sch     ON sch.id = v.school_id
    JOIN organizations o ON o.id = v.tenant_id
    WHERE length(replace(p_contains, '%', '')) >= 3
      AND (lower(v.display_name) LIKE p_contains
           OR lower(v.registration_no) LIKE p_contains
           OR regexp_replace(lower(v.registration_no), '[^[:alnum:]]', '', 'g') LIKE p_alphanumeric)
    ORDER BY lower(v.display_name) LIKE p_prefix DESC, v.display_name, v.id
    LIMIT LEAST(GREATEST(p_limit, 0), 26)
$$;

CREATE FUNCTION platform_search_routes(p_contains text, p_prefix text, p_limit integer)
    RETURNS TABLE (id uuid, organization_id uuid, organization_name varchar,
                   name varchar, code varchar, school_id uuid, school_name varchar)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT r.id, r.tenant_id, o.name, r.name, r.code, r.school_id, sch.name
    FROM routes r
    JOIN schools sch     ON sch.id = r.school_id
    JOIN organizations o ON o.id = r.tenant_id
    WHERE length(replace(p_contains, '%', '')) >= 3
      AND (lower(r.name) LIKE p_contains OR lower(r.code) LIKE p_contains)
    ORDER BY lower(r.name) LIKE p_prefix DESC, r.name, r.id
    LIMIT LEAST(GREATEST(p_limit, 0), 26)
$$;

CREATE FUNCTION platform_search_schools(p_contains text, p_prefix text, p_limit integer)
    RETURNS TABLE (id uuid, organization_id uuid, organization_name varchar,
                   name varchar, code varchar, status varchar)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT sch.id, sch.tenant_id, o.name, sch.name, sch.code, sch.status
    FROM schools sch
    JOIN organizations o ON o.id = sch.tenant_id
    WHERE length(replace(p_contains, '%', '')) >= 3
      AND (lower(sch.name) LIKE p_contains OR lower(sch.code) LIKE p_contains)
    ORDER BY lower(sch.name) LIKE p_prefix DESC, sch.name, sch.id
    LIMIT LEAST(GREATEST(p_limit, 0), 26)
$$;

-- "Administrative" is the Users screen's definition (UserJpaRepository.findAdministrativeUsers).
CREATE FUNCTION platform_search_administrative_users(p_contains text, p_digits text, p_prefix text, p_limit integer)
    RETURNS TABLE (id uuid, organization_id uuid, organization_name varchar,
                   first_name varchar, last_name varchar, email varchar, phone varchar,
                   status varchar, role_code varchar, school_id uuid, school_name varchar)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT u.id, u.tenant_id, o.name, u.first_name, u.last_name, u.email, u.phone, u.status,
           ar.code,
           CASE WHEN cs.scope_level = 'SCHOOL' THEN cs.scope_ref_id END,
           sch.name
    FROM users u
    JOIN organizations o ON o.id = u.tenant_id
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
    WHERE length(replace(p_contains, '%', '')) >= 3
      AND (lower(u.first_name || ' ' || u.last_name) LIKE p_contains
           OR lower(u.email) LIKE p_contains
           OR regexp_replace(u.phone, '[^0-9]', '', 'g') LIKE COALESCE(p_digits, ''))
    ORDER BY lower(u.first_name || ' ' || u.last_name) LIKE p_prefix DESC,
             u.first_name, u.last_name, u.id
    LIMIT LEAST(GREATEST(p_limit, 0), 26)
$$;

ALTER FUNCTION platform_search_students(text, text, integer) OWNER TO guardian_platform_ops;
ALTER FUNCTION platform_search_guardians(text, text, text, integer) OWNER TO guardian_platform_ops;
ALTER FUNCTION platform_search_staff(text, text, text, integer) OWNER TO guardian_platform_ops;
ALTER FUNCTION platform_search_vehicles(text, text, text, integer) OWNER TO guardian_platform_ops;
ALTER FUNCTION platform_search_routes(text, text, integer) OWNER TO guardian_platform_ops;
ALTER FUNCTION platform_search_schools(text, text, integer) OWNER TO guardian_platform_ops;
ALTER FUNCTION platform_search_administrative_users(text, text, text, integer) OWNER TO guardian_platform_ops;

REVOKE ALL ON FUNCTION platform_search_students(text, text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION platform_search_guardians(text, text, text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION platform_search_staff(text, text, text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION platform_search_vehicles(text, text, text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION platform_search_routes(text, text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION platform_search_schools(text, text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION platform_search_administrative_users(text, text, text, integer) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION platform_search_students(text, text, integer) TO guardian_app;
GRANT EXECUTE ON FUNCTION platform_search_guardians(text, text, text, integer) TO guardian_app;
GRANT EXECUTE ON FUNCTION platform_search_staff(text, text, text, integer) TO guardian_app;
GRANT EXECUTE ON FUNCTION platform_search_vehicles(text, text, text, integer) TO guardian_app;
GRANT EXECUTE ON FUNCTION platform_search_routes(text, text, integer) TO guardian_app;
GRANT EXECUTE ON FUNCTION platform_search_schools(text, text, integer) TO guardian_app;
GRANT EXECUTE ON FUNCTION platform_search_administrative_users(text, text, text, integer) TO guardian_app;

-- ---------------------------------------------------------------------------------------
-- Trigram indexes on exactly the expressions the search predicates use, in both paths.
-- ---------------------------------------------------------------------------------------
CREATE INDEX idx_students_search_name ON students
    USING gin (lower(first_name || ' ' || last_name) gin_trgm_ops);
CREATE INDEX idx_students_search_admission ON students
    USING gin (lower(admission_no) gin_trgm_ops);

CREATE INDEX idx_guardians_search_name ON guardians
    USING gin (lower(first_name || ' ' || last_name) gin_trgm_ops);
CREATE INDEX idx_guardians_search_phone ON guardians
    USING gin (regexp_replace(phone, '[^0-9]', '', 'g') gin_trgm_ops);
CREATE INDEX idx_guardians_search_email ON guardians
    USING gin (lower(email) gin_trgm_ops);

CREATE INDEX idx_transport_staff_search_name ON transport_staff
    USING gin (lower(first_name || ' ' || last_name) gin_trgm_ops);
CREATE INDEX idx_transport_staff_search_phone ON transport_staff
    USING gin (regexp_replace(phone, '[^0-9]', '', 'g') gin_trgm_ops);
CREATE INDEX idx_transport_staff_search_employee_code ON transport_staff
    USING gin (lower(employee_code) gin_trgm_ops);

CREATE INDEX idx_vehicles_search_display_name ON vehicles
    USING gin (lower(display_name) gin_trgm_ops);
CREATE INDEX idx_vehicles_search_registration ON vehicles
    USING gin (lower(registration_no) gin_trgm_ops);
CREATE INDEX idx_vehicles_search_registration_alnum ON vehicles
    USING gin (regexp_replace(lower(registration_no), '[^[:alnum:]]', '', 'g') gin_trgm_ops);

CREATE INDEX idx_routes_search_name ON routes USING gin (lower(name) gin_trgm_ops);
CREATE INDEX idx_routes_search_code ON routes USING gin (lower(code) gin_trgm_ops);

CREATE INDEX idx_schools_search_name ON schools USING gin (lower(name) gin_trgm_ops);
CREATE INDEX idx_schools_search_code ON schools USING gin (lower(code) gin_trgm_ops);

CREATE INDEX idx_users_search_name ON users
    USING gin (lower(first_name || ' ' || last_name) gin_trgm_ops);
CREATE INDEX idx_users_search_email ON users
    USING gin (lower(email) gin_trgm_ops);
CREATE INDEX idx_users_search_phone ON users
    USING gin (regexp_replace(phone, '[^0-9]', '', 'g') gin_trgm_ops);
