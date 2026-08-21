-- V3 — Identity & access (MOD-02)
--
-- See docs/03-database/tables/MOD-02-identity.md and ADR-0006.
--
-- Row-level security is applied HERE, in the same migration that creates the tables — a
-- table that exists for even one deploy without a policy was readable across tenants for
-- that deploy (V1 sets the precedent).
--
-- ## The pre-authentication problem
--
-- Every table below carries tenant_id and is therefore invisible without RLS context. But
-- authentication is where the tenant is *discovered*: at `POST /auth/otp/request` the
-- caller has supplied only a phone number, so `app.tenant_id` cannot yet be set and the
-- lookup that would resolve it returns zero rows.
--
-- The resolution is the pair of SECURITY DEFINER functions at the bottom of this file.
-- They run as the table owner, see all tenants, and return *only* the identifiers needed
-- to establish context — never profile data, never credential material. Everything after
-- that point runs with `app.tenant_id` set from the value they returned, under ordinary
-- RLS. Granting the application role BYPASSRLS instead would have removed isolation from
-- the entire application to solve one lookup.

-- ---------------------------------------------------------------------------------------
-- users — one row per person (BR-IAM-010: one user, several roles)
-- ---------------------------------------------------------------------------------------
CREATE TABLE users (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    email            VARCHAR(255),
    -- Stored normalised to digits-only with country code, so the same person typing
    -- "+91 80506 02046" or "08050602046" resolves to one row. Normalisation happens in
    -- PhoneNumber before it ever reaches SQL.
    phone            VARCHAR(32),
    first_name       VARCHAR(128) NOT NULL,
    last_name        VARCHAR(128) NOT NULL,
    -- Drives notification language. On the user, not the device: a shared handset and a
    -- parent who reads a different language than the phone's default are both ordinary.
    preferred_locale VARCHAR(16)  NOT NULL DEFAULT 'en',
    status           VARCHAR(24)  NOT NULL DEFAULT 'ACTIVE',
    last_login_at    TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by       UUID,
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by       UUID,
    version          BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT ck_users_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED')),
    -- Guardians authenticate by phone (many have no email), staff by email. At least one
    -- must exist or the row identifies nobody.
    CONSTRAINT ck_users_identifier CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

-- Partial unique indexes rather than table constraints: uniqueness applies only where the
-- column is present, and a table constraint cannot express that.
CREATE UNIQUE INDEX uq_users_tenant_email
    ON users (tenant_id, lower(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX uq_users_tenant_phone
    ON users (tenant_id, phone) WHERE phone IS NOT NULL;

CREATE INDEX idx_users_tenant_status ON users (tenant_id, status) WHERE status = 'ACTIVE';

-- Serves auth_resolve_phone below, which searches across tenants and so cannot use
-- uq_users_tenant_phone.
CREATE INDEX idx_users_phone ON users (phone) WHERE phone IS NOT NULL;

-- ---------------------------------------------------------------------------------------
-- user_credentials — password and OTP secrets
--
-- A separate table from users so credential material is never loaded by an ordinary user
-- query. Nothing here is ever returned by an API or written to a log.
-- ---------------------------------------------------------------------------------------
CREATE TABLE user_credentials (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    user_id         UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    credential_type VARCHAR(24)  NOT NULL,
    -- Argon2id. A six-digit OTP has ~20 bits of entropy, so a fast hash here would leave
    -- the whole space searchable from a database copy in seconds.
    secret_hash     VARCHAR(255) NOT NULL,
    expires_at      TIMESTAMPTZ,
    -- Set the moment a code is accepted. Single use is enforced by this column, not by
    -- deletion: a consumed code must stay visible for the audit trail.
    consumed_at     TIMESTAMPTZ,
    failed_attempts INTEGER      NOT NULL DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    version         BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT ck_user_credentials_type CHECK (credential_type IN ('PASSWORD', 'OTP')),
    CONSTRAINT ck_user_credentials_otp_expires
        CHECK (credential_type <> 'OTP' OR expires_at IS NOT NULL)
);

CREATE UNIQUE INDEX uq_user_credentials_password
    ON user_credentials (tenant_id, user_id) WHERE credential_type = 'PASSWORD';

-- The live-OTP lookup: newest first, and only rows that could still be accepted.
CREATE INDEX idx_user_credentials_otp
    ON user_credentials (tenant_id, user_id, created_at DESC)
    WHERE credential_type = 'OTP' AND consumed_at IS NULL;

-- ---------------------------------------------------------------------------------------
-- sessions — opaque refresh tokens, server-stored (ADR-0006)
-- ---------------------------------------------------------------------------------------
CREATE TABLE sessions (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    user_id             UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- SHA-256 of the token. The raw value exists only in the response body and on the
    -- client; a database copy does not yield usable sessions.
    refresh_token_hash  VARCHAR(255) NOT NULL,
    -- Rotation lineage. This column is what makes reuse detection possible at all
    -- (BR-IAM-009): without it, a stolen token that has already been rotated is
    -- indistinguishable from an unknown one.
    family_id           UUID         NOT NULL,
    previous_session_id UUID         REFERENCES sessions (id) ON DELETE SET NULL,
    client_type         VARCHAR(24)  NOT NULL,
    device_identifier   VARCHAR(255),
    issued_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    expires_at          TIMESTAMPTZ  NOT NULL,
    consumed_at         TIMESTAMPTZ,
    is_revoked          BOOLEAN      NOT NULL DEFAULT false,
    revoked_reason      VARCHAR(64),
    version             BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_sessions_refresh_hash UNIQUE (refresh_token_hash),
    CONSTRAINT ck_sessions_client_type
        CHECK (client_type IN ('PARENT_APP', 'DRIVER_APP', 'ADMIN_WEB'))
);

CREATE INDEX idx_sessions_user_active
    ON sessions (tenant_id, user_id) WHERE NOT is_revoked;
CREATE INDEX idx_sessions_family ON sessions (family_id);

-- ---------------------------------------------------------------------------------------
-- roles, user_roles
--
-- Roles are resolved per request from these tables, never carried in the access token
-- (BR-IAM-004). `permissions` and `role_permissions` arrive with permission resolution;
-- what exists here is what session establishment needs.
-- ---------------------------------------------------------------------------------------
CREATE TABLE roles (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    code           VARCHAR(32)  NOT NULL,
    name           VARCHAR(128) NOT NULL,
    -- Marks the templates from PERMISSION_MATRIX.md. Tenants may define their own roles
    -- from the same permission set; they cannot invent permissions.
    is_system_role BOOLEAN      NOT NULL DEFAULT false,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    version        BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_roles_tenant_code UNIQUE (tenant_id, code)
);

CREATE TABLE user_roles (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    user_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id    UUID        NOT NULL REFERENCES roles (id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_user_roles UNIQUE (tenant_id, user_id, role_id)
);

CREATE INDEX idx_user_roles_user ON user_roles (tenant_id, user_id);

-- ---------------------------------------------------------------------------------------
-- Row-level security
--
-- Same shape as V1: ENABLE + FORCE, one FOR ALL policy carrying both USING and WITH CHECK,
-- NULLIF so an unset context yields no rows rather than an error.
-- ---------------------------------------------------------------------------------------
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON users
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE user_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_credentials FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON user_credentials
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON sessions
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON roles
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON user_roles
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- guardian_preauth — the role the two pre-authentication functions run as
--
-- SECURITY DEFINER alone is NOT enough here, and the reason is easy to miss. The tables
-- above are declared FORCE ROW LEVEL SECURITY, and FORCE means the policy applies to the
-- table owner too. A SECURITY DEFINER function owned by guardian_owner would therefore
-- still be filtered by `tenant_id = current_setting('app.tenant_id')` — which, before
-- authentication, is unset. It would return zero rows, and no guardian could ever sign in.
--
-- Worse, that failure is invisible in a test container: Testcontainers creates the owner
-- as a SUPERUSER, and superusers bypass RLS unconditionally. The whole suite would pass
-- while production could not authenticate anybody.
--
-- So the functions are owned by a role that genuinely bypasses RLS, and that role is made
-- as small as it can be:
--
--   NOLOGIN     it cannot open a connection; nothing can present it as a credential
--   NOINHERIT   membership does not silently confer it
--   BYPASSRLS   the one privilege it exists for
--   SELECT on exactly two tables, and no other object
--
-- The blast radius is therefore the two function bodies below, both of which return
-- identifiers only. Compare the alternative that suggests itself first — granting
-- BYPASSRLS to guardian_app — which would remove row-level security from every query the
-- application makes.
-- ---------------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'guardian_preauth') THEN
        BEGIN
            CREATE ROLE guardian_preauth NOLOGIN NOINHERIT BYPASSRLS;
        EXCEPTION WHEN insufficient_privilege THEN
            -- Only a superuser may grant BYPASSRLS. Where migrations do not run as one, the
            -- role is provisioned alongside guardian_app before deployment; failing here with
            -- the exact statement needed beats a schema that migrates and then cannot
            -- authenticate anyone.
            RAISE EXCEPTION
                'guardian_preauth must exist before this migration. Run as superuser: '
                'CREATE ROLE guardian_preauth NOLOGIN NOINHERIT BYPASSRLS;';
        END;
    END IF;
END
$$;

GRANT SELECT ON users, sessions TO guardian_preauth;

-- ---------------------------------------------------------------------------------------
-- Pre-authentication resolution
--
-- The only two places in the platform where a query crosses tenants. Both are deliberately
-- minimal:
--
--   * They return identifiers ONLY. No name, no locale, no hash. A caller learns which
--     tenant to establish context for and nothing else, so a defect here cannot become a
--     data leak — the follow-up read still runs under RLS.
--   * `SET search_path = public` is not optional on a SECURITY DEFINER function: without it
--     a caller-controlled search_path can shadow `users` with their own table and change
--     what the function returns.
--   * EXECUTE is revoked from PUBLIC and granted only to guardian_app.
--
-- auth_resolve_phone deliberately does not filter on status. Distinguishing "unknown
-- number" from "locked account" at this layer would let an attacker enumerate registered
-- guardians by timing or response; status is checked afterwards, on the ordinary path,
-- where the answer is already uniform.
-- ---------------------------------------------------------------------------------------
CREATE FUNCTION auth_resolve_phone(p_phone TEXT)
    RETURNS TABLE (user_id UUID, tenant_id UUID, status TEXT)
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
AS $$
    SELECT u.id, u.tenant_id, u.status
    FROM users u
    WHERE u.phone = p_phone;
$$;

-- Ownership is transferred before the grants are set, because ALTER OWNER does not disturb
-- an ACL but the order reads as the sequence it is: whose privileges the body runs with,
-- then who may invoke it.
ALTER FUNCTION auth_resolve_phone(TEXT) OWNER TO guardian_preauth;
REVOKE ALL ON FUNCTION auth_resolve_phone(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_resolve_phone(TEXT) TO guardian_app;

-- Refresh presents only an opaque token, so the tenant is unknown for exactly the same
-- reason. Returns the session id and its tenant; every check that decides whether the
-- token is acceptable runs afterwards under RLS.
CREATE FUNCTION auth_resolve_refresh_token(p_token_hash TEXT)
    RETURNS TABLE (session_id UUID, tenant_id UUID)
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
AS $$
    SELECT s.id, s.tenant_id
    FROM sessions s
    WHERE s.refresh_token_hash = p_token_hash;
$$;

ALTER FUNCTION auth_resolve_refresh_token(TEXT) OWNER TO guardian_preauth;
REVOKE ALL ON FUNCTION auth_resolve_refresh_token(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_resolve_refresh_token(TEXT) TO guardian_app;

-- ---------------------------------------------------------------------------------------
-- Grants
--
-- No DELETE on sessions or user_credentials: sessions are revoked, OTPs are consumed, and
-- both remain as evidence. A DELETE grant would make "log out everywhere" indistinguishable
-- from "erase the record that a session existed".
-- ---------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE          ON users, roles            TO guardian_app;
GRANT SELECT, INSERT, UPDATE          ON user_credentials        TO guardian_app;
GRANT SELECT, INSERT, UPDATE          ON sessions                TO guardian_app;
GRANT SELECT, INSERT, UPDATE, DELETE  ON user_roles              TO guardian_app;
