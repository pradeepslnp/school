-- V10 — Staff login resolution (IAM-001)
--
-- POST /auth/login authenticates staff by email + password (AUTHENTICATION_API.md), which has
-- the same bootstrap problem V3's comment describes for the guardian OTP flow: at the point the
-- caller presents an email address, no tenant context exists yet, so app.tenant_id is unset and
-- an ordinary query against `users` — RLS-protected since V3 — returns nothing.
--
-- No table changes are needed. `users.email` and `user_credentials` with credential_type =
-- 'PASSWORD' already exist from V3, exactly for this. What is missing is the second
-- SECURITY DEFINER resolver, alongside auth_resolve_phone rather than replacing it — a phone
-- lookup for a guardian and an email lookup for staff are the same shape solving the same
-- problem for a different identifier, not one function overloaded on meaning.
--
-- Same discipline as auth_resolve_phone: identifiers and status only, no name, no credential
-- material, owned by guardian_preauth (which V3 already created and granted BYPASSRLS —
-- provisioning it twice would fail loudly rather than silently, so it is not repeated here),
-- search_path pinned, EXECUTE revoked from PUBLIC and granted only to guardian_app.

CREATE FUNCTION auth_resolve_email(p_email TEXT)
    RETURNS TABLE (user_id UUID, tenant_id UUID, status TEXT)
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
AS $$
    -- Case-insensitive, matching uq_users_tenant_email's lower(email) index — a staff member
    -- who typed their address with different capitalisation than it was provisioned with must
    -- still resolve, or "wrong password" becomes the wrong diagnosis for a right password.
    SELECT u.id, u.tenant_id, u.status
    FROM users u
    WHERE lower(u.email) = lower(p_email);
$$;

ALTER FUNCTION auth_resolve_email(TEXT) OWNER TO guardian_preauth;
REVOKE ALL ON FUNCTION auth_resolve_email(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_resolve_email(TEXT) TO guardian_app;
