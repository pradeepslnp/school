-- V16 — Administrative account invitations & password reset (ADR-0012, IAM-009/IAM-010)
--
-- Adds the two things the invite/reset flow needs on top of the identity schema, and no more:
--   1. a PENDING user status — an account created by invitation that has no password yet and
--      cannot sign in until the invitation is accepted;
--   2. two link-token credential types, INVITE and RESET, stored in the existing user_credentials
--      table (they have the exact shape it already models: a hashed secret, an expiry, and a
--      consumed-at for single use), plus the pre-auth resolver the public accept/reset endpoints
--      use to find an account from a token alone.
--
-- Deliberately NO new table. user_credentials already carries secret_hash / expires_at /
-- consumed_at under tenant-scoped RLS; a second table would duplicate that pattern for no gain
-- (ADR-0012, KISS). No new RLS surface is introduced as a result.

-- 1. PENDING user status ---------------------------------------------------------------------
ALTER TABLE users DROP CONSTRAINT ck_users_status;
ALTER TABLE users
    ADD CONSTRAINT ck_users_status
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED', 'PENDING'));

-- 2. INVITE / RESET credential types -----------------------------------------------------------
ALTER TABLE user_credentials DROP CONSTRAINT ck_user_credentials_type;
ALTER TABLE user_credentials
    ADD CONSTRAINT ck_user_credentials_type
    CHECK (credential_type IN ('PASSWORD', 'OTP', 'INVITE', 'RESET'));

-- A link token, like an OTP, is meaningless without an expiry — the same integrity guard the OTP
-- type already carries (ck_user_credentials_otp_expires), extended to the two new kinds.
ALTER TABLE user_credentials
    ADD CONSTRAINT ck_user_credentials_link_expires
    CHECK (credential_type NOT IN ('INVITE', 'RESET') OR expires_at IS NOT NULL);

-- 3. Pre-auth token resolver -------------------------------------------------------------------
-- Same bootstrap problem as auth_resolve_email (V10): the accept-invitation and reset-password
-- endpoints present only a token, so no tenant context exists yet and an ordinary RLS-protected
-- query against user_credentials returns nothing. The resolver crosses tenants once to answer
-- "whose token is this?", returning identifiers only — no secret, no profile — after which the
-- caller establishes the tenant and does every mutation under ordinary RLS.
--
-- Same discipline as the existing resolvers: owned by guardian_preauth (created and granted
-- BYPASSRLS in V3), search_path pinned, EXECUTE revoked from PUBLIC and granted only to
-- guardian_app. The lookup is by secret_hash, which for INVITE/RESET is a deterministic SHA-256
-- of the 256-bit token (ADR-0012) — safe to store and to match on, unlike a salted password hash.
--
-- guardian_preauth already holds SELECT on users and sessions (V3); it needs the same on
-- user_credentials to read within this function.
GRANT SELECT ON user_credentials TO guardian_preauth;

CREATE FUNCTION auth_resolve_account_token(p_hash TEXT, p_type TEXT)
    RETURNS TABLE (credential_id UUID, user_id UUID, tenant_id UUID)
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
AS $$
    SELECT c.id, c.user_id, c.tenant_id
    FROM user_credentials c
    WHERE c.secret_hash = p_hash
      AND c.credential_type = p_type;
$$;

ALTER FUNCTION auth_resolve_account_token(TEXT, TEXT) OWNER TO guardian_preauth;
REVOKE ALL ON FUNCTION auth_resolve_account_token(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_resolve_account_token(TEXT, TEXT) TO guardian_app;
