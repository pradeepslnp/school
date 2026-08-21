-- Ad-hoc test data: duplicate login (phone 8050602046) under a second organization.
--
-- NOT part of the Flyway migration chain and NOT meant to be committed to
-- db/seed/V900__demo_data.sql. That file is the baseline every developer's `demo` profile
-- loads automatically; permanently making 8050602046 ambiguous there would break the sign-in
-- flow (GUARDIAN_MAGIC_OTP=123123) the parent app's own test fixtures rely on for everyone
-- else. Run this by hand, only in the local dev database, only when you specifically want to
-- test the duplicate-phone scenario:
--
--   docker compose -f ../guardian-infra/docker-compose.yml up -d      # if not already running
--   psql "$GUARDIAN_DB_URL" -f seed-duplicate-login-8050602046.sql
--
-- (Or `psql postgresql://guardian_owner@localhost:5432/guardian -f ...` — use the owner role,
-- not guardian_app, matching how V900__demo_data.sql itself is applied: FORCE ROW LEVEL
-- SECURITY applies to every role including the owner, so SET LOCAL app.tenant_id is what makes
-- each INSERT below pass its own WITH CHECK, exactly as in V900.)
--
-- What this creates
--
-- The existing seed (V900) has exactly one organization, "Demo Education Trust"
-- (a0000000-0000-4000-a000-000000000001), with one user on phone 8050602046 ("Meera Sharma").
-- `uq_users_tenant_phone` is scoped to (tenant_id, phone) — unique per organization, not
-- globally — so a genuine duplicate row for this phone number can only exist under a
-- *different* organization; the schema itself refuses a same-tenant duplicate. This script
-- adds a second organization and a second user record on the same phone number there, which
-- is the same shape as the gap your own traceability notes flag under BR-IAM-003: nothing yet
-- stops one phone number resolving to two different people in two different organizations, and
-- the OTP sign-in path only guards against the ambiguity rather than preventing it at the data
-- level. Signing in with 8050602046 after running this script is one way to see what that path
-- currently does with two matches.
--
-- To remove it again, see the commented DELETE block at the bottom.

BEGIN;

-- Second organization's id also seeds its own RLS context, same as V900 does for the first.
SET LOCAL app.tenant_id = 'a0000000-0000-4000-a000-000000000002';

INSERT INTO organizations (id, code, name, region_profile_code, status, contact_email)
VALUES ('a0000000-0000-4000-a000-000000000002', 'DEMO-B', 'Demo Education Trust — Branch Campus',
        'IN', 'ACTIVE', 'branch-office@demo-trust.example')
ON CONFLICT (id) DO NOTHING;

INSERT INTO schools (id, tenant_id, organization_id, code, name, timezone,
                     latitude, longitude, geofence_radius_m, status)
VALUES ('b0000000-0000-4000-a000-000000000002',
        'a0000000-0000-4000-a000-000000000002',
        'a0000000-0000-4000-a000-000000000002',
        'DPS-BC', 'Demo Public School, Branch Campus', 'Asia/Kolkata',
        28.601500, 77.190000, 150, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- Same phone number as the seeded user under the first organization
-- (c0000000-0000-4000-a000-000000000001) — deliberately, this row's whole purpose is to
-- collide on phone across a tenant boundary.
INSERT INTO users (id, tenant_id, phone, first_name, last_name, preferred_locale, status)
VALUES ('c0000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000002',
        '8050602046', 'Meera', 'Sharma (Branch Campus)', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO guardians (id, tenant_id, user_id, first_name, last_name, phone, email, is_active)
VALUES ('c1000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000002',
        'c0000000-0000-4000-a000-000000000002', 'Meera', 'Sharma (Branch Campus)', '8050602046',
        'meera.sharma.branch@example.com', true)
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- --------------------------------------------------------------------------------------
-- To undo: run this block by itself (also needs its own tenant context, per RLS above).
-- --------------------------------------------------------------------------------------
-- BEGIN;
-- SET LOCAL app.tenant_id = 'a0000000-0000-4000-a000-000000000002';
-- DELETE FROM guardians     WHERE id = 'c1000000-0000-4000-a000-000000000002';
-- DELETE FROM users         WHERE id = 'c0000000-0000-4000-a000-000000000002';
-- DELETE FROM schools       WHERE id = 'b0000000-0000-4000-a000-000000000002';
-- DELETE FROM organizations WHERE id = 'a0000000-0000-4000-a000-000000000002';
-- COMMIT;
