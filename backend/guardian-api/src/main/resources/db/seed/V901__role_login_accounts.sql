-- V901 — One admin-console login per role. NOT part of the production migration path.
--
-- Lives in `db/seed` alongside V900, which the `demo` profile alone adds to
-- spring.flyway.locations (application-demo.yml). A production deployment never sees this file.
--
-- ## What this adds that V900 does not
--
-- V900 seeds the fixtures the parent and driver apps need, plus two console accounts on reserved
-- `.example` addresses that can never receive mail. That is enough to demo the apps but not to
-- exercise the console's authorisation, which differs per role, and not to exercise email at all.
--
-- The accounts below use **real addresses**, so the whole account lifecycle runs end to end:
-- invitation → set your own password → sign in → forgot password → reset. Nothing here depends on
-- the fixed development code; every one of these addresses receives a genuine generated code,
-- delivered by whichever AccountEmailSender is active (logged until guardian.mail.enabled=true).
--
-- The V900 `.example` accounts are left in place — AUTHENTICATION_API.md's examples and the parent
-- app's fixtures reference them — but they are not the accounts to sign in with any more. Use the
-- ones below.
--
-- ## Both sign-in methods work for every account
--
--   * email + password        POST /auth/login
--   * email + one-time code   POST /auth/email-otp/request → /auth/email-otp/verify
--
-- Initial password for every account below: Guardian!Demo2026
-- It is a starting credential, not a permanent one: the reset flow is the intended way to replace
-- it, and doing so is the simplest end-to-end test of the email path.
--
-- ## user_scopes matter as much as roles
--
-- A role says what a person may do; a scope says which organization or school they may do it to
-- (BR-IAM-006). Without the scope rows below a SCHOOL_ADMIN signs in and then finds the School
-- screen unreachable, because the console reads schoolScopeId from the session and there is none.
-- V900 predates user_scopes (V15) and seeds no scope rows, so its two accounts are given theirs
-- here too rather than left half-configured.
--
-- ## Real addresses in a committed file
--
-- These are live mailboxes belonging to real people. That is deliberate — they are what makes the
-- email flows testable — but it does mean the addresses are in git history. If this repository is
-- ever shared more widely, replace them here rather than assuming the seed is private.
--
-- SET LOCAL app.tenant_id is load-bearing — see V900's header for why (FORCE ROW LEVEL SECURITY
-- applies to the table owner Flyway connects as).

-- =======================================================================================
-- Platform-operations tenant — SUPER_ADMIN
-- =======================================================================================
SET LOCAL app.tenant_id = 'aa000000-0000-4000-a000-000000000001';

-- The platform organization and the SUPER_ADMIN role already exist (V900); repeated here only so
-- this file also applies to a database seeded before V900 gained them.
INSERT INTO organizations (id, code, name, region_profile_code, status, contact_email)
VALUES ('aa000000-0000-4000-a000-000000000001', 'PLATFORM', 'Guardian Platform Operations',
        'GLOBAL', 'ACTIVE', 'platform-ops@guardian.example')
ON CONFLICT (id) DO NOTHING;

INSERT INTO roles (id, tenant_id, code, name, is_system_role)
VALUES ('ad000000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'SUPER_ADMIN', 'Super Admin', true)
ON CONFLICT (id) DO NOTHING;

-- Priya (V900) had no scope row; a SUPER_ADMIN's scope is PLATFORM and carries no ref id.
INSERT INTO user_scopes (id, tenant_id, user_id, scope_level, scope_ref_id)
VALUES ('b9000000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'ab000000-0000-4000-a000-000000000001', 'PLATFORM', NULL)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- SUPER_ADMIN — pradeepslnp7@gmail.com
--
-- The ids here match the standalone make_super_admin.sql handed over earlier, on purpose: if that
-- script has already been run against this database, every insert below is a clean no-op instead
-- of colliding with uq_users_tenant_email (which ON CONFLICT (id) would NOT have caught, because
-- the conflict would be on the email index rather than the primary key — a failed migration).
-- ---------------------------------------------------------------------------------------
INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
VALUES ('af000000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'pradeepslnp7@gmail.com', 'Pradeep', 'Admin', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_credentials (id, tenant_id, user_id, credential_type, secret_hash)
VALUES ('af100000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'af000000-0000-4000-a000-000000000001', 'PASSWORD',
        '$argon2id$v=19$m=16384,t=2,p=1$koCY9Y0xjpWNyxs54D6gTA$HL49qsWcQPuYzmEtNXBpGpFPqrR/k44qLD2tkAwJsAQ')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('af200000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'af000000-0000-4000-a000-000000000001', 'ad000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_scopes (id, tenant_id, user_id, scope_level, scope_ref_id)
VALUES ('af300000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'af000000-0000-4000-a000-000000000001', 'PLATFORM', NULL)
ON CONFLICT (id) DO NOTHING;

-- =======================================================================================
-- Demo trust tenant — the organization- and school-scoped roles
-- =======================================================================================
SET LOCAL app.tenant_id = 'a0000000-0000-4000-a000-000000000001';

-- The roles this tenant needs. TRANSPORT_MANAGER already exists from V900.
INSERT INTO roles (id, tenant_id, code, name, is_system_role)
VALUES ('d1000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'ORG_ADMIN', 'Organization Admin', true),
       ('d1000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        'SCHOOL_ADMIN', 'School Admin', true),
       ('d1000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001',
        'PRINCIPAL', 'Principal', true)
ON CONFLICT (id) DO NOTHING;

-- Anil (V900, TRANSPORT_MANAGER) had no scope row — his role is school-scoped.
INSERT INTO user_scopes (id, tenant_id, user_id, scope_level, scope_ref_id)
VALUES ('d2000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'c7000000-0000-4000-a000-000000000001', 'SCHOOL',
        'b0000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- ORG_ADMIN — pradeepslnp07@gmail.com. Organization-scoped: no school ref.
INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
VALUES ('d3000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'pradeepslnp07@gmail.com', 'Org', 'Admin', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_credentials (id, tenant_id, user_id, credential_type, secret_hash)
VALUES ('d4000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'd3000000-0000-4000-a000-000000000001', 'PASSWORD',
        '$argon2id$v=19$m=16384,t=2,p=1$4g/WLXogxMLHcAudFfnvgA$7YJUdBOEYbFmxzF4TLESDybRd2A76MkjmZZoJwrUV9w')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('d5000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'd3000000-0000-4000-a000-000000000001', 'd1000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_scopes (id, tenant_id, user_id, scope_level, scope_ref_id)
VALUES ('d6000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'd3000000-0000-4000-a000-000000000001', 'ORG', NULL)
ON CONFLICT (id) DO NOTHING;

-- SCHOOL_ADMIN — akshay5632@gmail.com. School-scoped.
INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
VALUES ('d7000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'akshay5632@gmail.com', 'School', 'Admin', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_credentials (id, tenant_id, user_id, credential_type, secret_hash)
VALUES ('d8000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'd7000000-0000-4000-a000-000000000001', 'PASSWORD',
        '$argon2id$v=19$m=16384,t=2,p=1$osKpXl+GciutX2dKqvl8Cg$6sKK16LpAGoo5ZJuYAcVOzOsWEjA7FPoXv+cmCzMgaE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('d9000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'd7000000-0000-4000-a000-000000000001', 'd1000000-0000-4000-a000-000000000002')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_scopes (id, tenant_id, user_id, scope_level, scope_ref_id)
VALUES ('da000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'd7000000-0000-4000-a000-000000000001', 'SCHOOL',
        'b0000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- PRINCIPAL — reelsatdesk@gmail.com. School-scoped, read-mostly (PERMISSION_MATRIX.md).
INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
VALUES ('db000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'reelsatdesk@gmail.com', 'School', 'Principal', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_credentials (id, tenant_id, user_id, credential_type, secret_hash)
VALUES ('dc000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'db000000-0000-4000-a000-000000000001', 'PASSWORD',
        '$argon2id$v=19$m=16384,t=2,p=1$aPwtb7c+tQIL22r8XcczaA$DSnyc8GZK0NtY0ey6lk/bC+tUQ8zDOoVQDEXoZjHK28')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('dd000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'db000000-0000-4000-a000-000000000001', 'd1000000-0000-4000-a000-000000000003')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_scopes (id, tenant_id, user_id, scope_level, scope_ref_id)
VALUES ('de000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'db000000-0000-4000-a000-000000000001', 'SCHOOL',
        'b0000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- TRANSPORT_MANAGER — 7625055445l@gmail.com. School-scoped.
INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
VALUES ('df000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        '7625055445l@gmail.com', 'Transport', 'Manager', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_credentials (id, tenant_id, user_id, credential_type, secret_hash)
VALUES ('e3000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'df000000-0000-4000-a000-000000000001', 'PASSWORD',
        '$argon2id$v=19$m=16384,t=2,p=1$kprmhucaI8r/OZl/eDCH4Q$tgUhuNeFsOQuahTHVNpitrbWhB6jV2+5NQiQvVOYbLg')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('e4000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'df000000-0000-4000-a000-000000000001', 'c9000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_scopes (id, tenant_id, user_id, scope_level, scope_ref_id)
VALUES ('e5000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'df000000-0000-4000-a000-000000000001', 'SCHOOL',
        'b0000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;
