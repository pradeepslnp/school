-- Database cleanup after reverting the email-OTP sign-in experiment.
--
-- BACKGROUND
--
-- Commits 44b313f / 462c9ff reverted "IAM-001: email one-time-code sign-in + role login
-- accounts". Two Flyway versions were caught in that revert:
--
--   * version 17  was V17__email_otp_sign_in.sql (added a LOGIN_OTP credential type).
--   * version 901 was V901__role_login_accounts.sql (seeded one console login per role).
--
-- Both version numbers have since been REUSED by legitimate migrations:
--
--   * version 17  is now V17__student_bulk_import.sql  (real, current).
--   * version 901 is now V901__role_login_accounts.sql (restored — email+password only,
--                 no email-OTP — under db/seed, demo profile).
--
-- So a plain "delete versions 17 and 901 from the history" is no longer safe: it would orphan
-- the real V17 and force Flyway to re-run it against tables that already exist.
--
-- WHEN YOU STILL NEED THIS
--
-- Only if this database applied the OLD email-OTP V17 before the revert, and Flyway now refuses
-- to start with a checksum mismatch or "Detected applied migration not resolved locally: 17".
-- The guarded DELETE below removes that row ONLY IF its description is the reverted one, then the
-- current V17 (student bulk import) applies cleanly on the next start.
--
-- If the backend starts fine, you do not need this file. Check first:
--
--   SELECT version, description, checksum FROM flyway_schema_history WHERE version = '17';
--
-- HOW TO RUN
--
--   psql "postgresql://guardian_owner:local_owner@localhost:5432/guardian" -f revert_cleanup.sql
--
-- Idempotent: running it twice changes nothing the second time.

BEGIN;

-- Remove the history row for the reverted email-OTP V17 *only*. The description guard means this
-- is a no-op on a database whose version 17 is the current student-bulk-import migration.
DELETE FROM flyway_schema_history
WHERE version = '17'
  AND description IN ('email otp sign in', 'email otp signin');

-- The reverted V901 and the restored V901 share a description, and the restored one is a real
-- migration, so its history row is left alone. If this database applied the reverted V901 and
-- Flyway complains about a version-901 checksum mismatch, run `./gradlew :guardian-api:flywayRepair`
-- (or delete only that row after confirming its checksum differs from the current file's).

COMMIT;

-- Deliberately NOT undone: the widened CHECK on user_credentials.credential_type (the reverted
-- V17 added 'LOGIN_OTP'). A permitted value nothing writes is harmless; narrowing it again would
-- fail if any LOGIN_OTP row exists from a test sign-in.

SELECT version, description, success
FROM flyway_schema_history
ORDER BY installed_rank DESC
LIMIT 8;
