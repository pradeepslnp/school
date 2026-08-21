-- V12 — List every organization on the platform, for SUPER_ADMIN only (TEN-001).
--
-- The admin console's Organizations screen (A-40) needs a list, not just a single row: an
-- operator must be able to see and reopen an organization they created earlier, not only the
-- one from their current session. An ordinary tenant-scoped SELECT against `organizations`
-- cannot answer this — RLS (V1__baseline_tenancy.sql) restricts every request to
-- `id = app.tenant_id`, and for a SUPER_ADMIN that is the platform-operations organization's
-- own row, not every tenant's.
--
-- This is a narrower, explicitly interim answer to the same underlying problem
-- UpdateOrganizationUseCase already documents: the platform's real answer to genuine
-- cross-tenant reads is the audited elevation path (BR-TEN-004 🔴, PERM-PLATFORM-TENANT-ACCESS,
-- screen A-60) — justification captured, an audit record written, *then* access opens. That
-- path is not built yet. Rather than block "see the organizations I already created" on it,
-- this migration adds the smallest thing that unblocks it safely:
--
--   * `guardian_platform_ops` — a new, non-login, BYPASSRLS role. Not `guardian_preauth`,
--     even though the mechanics are identical (SECURITY DEFINER function owned by a BYPASSRLS
--     role, narrow GRANT to guardian_app) — `guardian_preauth` is a *pre-authentication*
--     concept (V3__identity.sql) and this read happens well after authentication, by an
--     already-identified SUPER_ADMIN. Naming it separately also gives BR-TEN-004's future
--     elevation path a role to grow into, instead of overloading this one further.
--   * `list_organizations()` — returns every row, unfiltered. This is deliberately wider than
--     `org_code_exists` (V11, a single boolean): a list screen needs the rows. The safety
--     boundary is therefore enforced in the application layer, not the database — see
--     ListOrganizationsUseCase, which refuses any caller whose role is not literally
--     SUPER_ADMIN before this function is ever invoked. RLS_POLICIES.md's "no code path turns
--     RLS off" still holds for every *other* table and every *other* caller; this one function,
--     for this one role, is the documented, narrow exception until BR-TEN-004 replaces it.
--
-- Same GRANT lesson as V11: BYPASSRLS skips policies, not the underlying table GRANT.

CREATE ROLE guardian_platform_ops NOLOGIN NOINHERIT BYPASSRLS;

GRANT SELECT ON organizations TO guardian_platform_ops;

CREATE FUNCTION list_organizations()
    RETURNS SETOF organizations
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
AS $$
    SELECT * FROM organizations ORDER BY name;
$$;

ALTER FUNCTION list_organizations() OWNER TO guardian_platform_ops;
REVOKE ALL ON FUNCTION list_organizations() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION list_organizations() TO guardian_app;
