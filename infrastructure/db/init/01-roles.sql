-- Creates the runtime database role.
--
-- Runs once, on first container start, before any migration.
--
-- The separation between guardian_owner and guardian_app is the foundation of tenant
-- isolation (ADR-0001):
--
--   guardian_owner  owns schema objects; used by Flyway only
--   guardian_app    the application runtime — NOT the owner, and NOBYPASSRLS
--
-- Running the application as the owner would defeat row-level security entirely while
-- breaking nothing visible: every query would still work, and every tenant would see
-- every child. That failure is silent, which is why RlsSchemaInvariantsIT asserts the
-- role's configuration explicitly rather than trusting this file.
--
-- See docs/03-database/RLS_POLICIES.md.

CREATE ROLE guardian_app LOGIN PASSWORD 'local_app' NOBYPASSRLS;

GRANT CONNECT ON DATABASE guardian TO guardian_app;
GRANT USAGE ON SCHEMA public TO guardian_app;

-- Table-level grants are issued by the migration that creates each table, so a new table
-- is unreachable until its migration deliberately opens it. Notably, append-only tables
-- receive INSERT and SELECT only — never UPDATE or DELETE (BR-AUD-001).
