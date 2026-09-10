-- V901 — One admin-console login per role. NOT part of the production migration path.
--
-- Lives in `db/seed` alongside V900, which the `demo` profile alone adds to
-- spring.flyway.locations (application-demo.yml). A production deployment never sees this file.
--
-- ## What this adds that V900 does not
--
-- V900 seeds the parent- and driver-app fixtures plus two console accounts on reserved `.example`
-- addresses that can never receive mail — enough to demo those apps, but not enough to exercise
-- the console, whose authorisation differs per role: what a PRINCIPAL sees is not what an
-- ORG_ADMIN sees. This file completes the set so every admin-console role in PERMISSION_MATRIX.md
-- has an account.
--
-- Sign-in is **email + password** at `POST /auth/login` (ADR-0006, ADR-0012). Onboarding a real
-- operator is by email invitation → set password; these seeded accounts skip that and are handed
-- a starting password directly.
--
--   Initial password for every account below: Guardian!Demo2026
--
-- It is a starting credential, not a permanent one — the reset flow (emailed 6-digit code) is the
-- intended way to replace it, and on the demo profile that code is always 123123
-- (guardian.auth.magic-otp). Real email delivery is not wired: LoggingAccountEmailSender writes
-- the code to the backend log.
--
-- ## user_scopes matter as much as roles
--
-- A role says what a person may do; a scope says which organization or school they may do it to
-- (BR-IAM-006). Without the scope rows below a SCHOOL_ADMIN signs in and then finds the School
-- screen unreachable, because the console reads schoolScopeId off the session and there is none.
-- V900 predates user_scopes (V15) and seeds none, so its two accounts (Anil, Priya) are given
-- theirs here too rather than left half-configured.
--
-- ## Real addresses in a committed file
--
-- These are live mailboxes belonging to real people — deliberate, so the invite / reset flows are
-- testable against a genuine inbox once an email sender is configured — but it does mean the
-- addresses are in git history. If this repository is shared more widely, replace them here.
--
-- The SUPER_ADMIN ids match the standalone make_super_admin.sql handed over earlier, on purpose:
-- if that script already ran against this database, every insert below is a clean no-op. If
-- pradeepslnp7@gmail.com already exists under a *different* id, delete that stray row (or align
-- its id) before this seed runs — the ON CONFLICT (id) guard cannot catch a uq_users_tenant_email
-- collision.
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
