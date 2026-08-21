-- V11 — Organization code uniqueness check (TEN-001)
--
-- POST /organizations has the same bootstrap problem V3 and V10 solve for authentication, one
-- level earlier: creating an organization mints a brand-new tenant, so before it exists there is
-- no app.tenant_id to set, and the actor's own session tenant (a platform-operations
-- organization, for a SUPER_ADMIN) is not the tenant being written. An ordinary tenant-scoped
-- SELECT against `organizations` — RLS-protected since V1, policy compares id = app.tenant_id —
-- would only ever see the actor's own row and could never detect a code already used by another
-- organization (BR-TEN-007).
--
-- Same discipline as auth_resolve_phone / auth_resolve_email: the narrowest possible answer
-- (a boolean, not the row), owned by guardian_preauth (already BYPASSRLS via V3, not repeated
-- here), search_path pinned, EXECUTE revoked from PUBLIC and granted only to guardian_app. The
-- database's unique index on `code` is still the real enforcement of BR-TEN-007; this function
-- only turns a would-be constraint violation into a checkable fact so the use case can return
-- ORG_CODE_ALREADY_EXISTS instead of a raw write failure.
--
-- BYPASSRLS (V3) skips row-level security *policies* — it is not a substitute for the
-- ordinary SQL GRANT, which V1 gave only to guardian_app. Without the SELECT below,
-- guardian_preauth can see past RLS and still be refused by the table itself.

GRANT SELECT ON organizations TO guardian_preauth;

CREATE FUNCTION org_code_exists(p_code TEXT)
    RETURNS BOOLEAN
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
AS $$
    SELECT EXISTS (SELECT 1 FROM organizations WHERE code = upper(p_code));
$$;

ALTER FUNCTION org_code_exists(TEXT) OWNER TO guardian_preauth;
REVOKE ALL ON FUNCTION org_code_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION org_code_exists(TEXT) TO guardian_app;
