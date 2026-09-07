-- Database cleanup after reverting the email-OTP sign-in work.
--
-- WHEN YOU NEED THIS
--
-- Only if you already started the backend with the demo profile while V17 (LOGIN_OTP) and/or
-- V901 (role login accounts) existed. Flyway recorded those versions as applied; now that the
-- files are gone it will refuse to start with:
--
--     Detected applied migration not resolved locally: 17
--     Detected applied migration not resolved locally: 901
--
-- If the backend starts fine, you do not need this file.
--
-- HOW TO RUN
--
--   psql "postgresql://guardian_owner:local_owner@localhost:5432/guardian" -f revert_cleanup.sql
--
-- (adjust the password if GUARDIAN_DB_OWNER_PASSWORD is set to something else)
--
-- Idempotent: running it twice changes nothing the second time.

BEGIN;

-- Forget the two reverted migrations. Nothing else in the history is touched.
DELETE FROM flyway_schema_history WHERE version IN ('17', '901');

COMMIT;

-- Deliberately NOT undone:
--
--   * The widened CHECK on user_credentials.credential_type (V17 added 'LOGIN_OTP' to the list).
--     Leaving a value permitted that nothing writes is harmless, and narrowing it again would
--     fail if any LOGIN_OTP row happens to exist from a test sign-in.
--
--   * The accounts V901 seeded, if it ran. They are ordinary user rows with roles and scopes —
--     including the SUPER_ADMIN on pradeepslnp7@gmail.com, which is worth keeping. If you would
--     rather remove the extra role accounts, deactivate rather than delete so audit records that
--     reference them stay valid:
--
--       SET app.tenant_id = 'a0000000-0000-4000-a000-000000000001';
--       UPDATE users SET status = 'INACTIVE'
--       WHERE id IN ('d3000000-0000-4000-a000-000000000001',
--                    'd7000000-0000-4000-a000-000000000001',
--                    'db000000-0000-4000-a000-000000000001',
--                    'df000000-0000-4000-a000-000000000001');

-- Verify the history no longer mentions them.
SELECT version, description, success
FROM flyway_schema_history
ORDER BY installed_rank DESC
LIMIT 8;
