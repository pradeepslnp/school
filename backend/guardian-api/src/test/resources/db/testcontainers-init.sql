-- Runs once when the test container starts, before Flyway.
--
-- Creates the runtime role exactly as production does: NOT the owner, and explicitly
-- NOBYPASSRLS. Tests connect as this role so that a misconfiguration which would defeat
-- row-level security fails a test rather than reaching production.

CREATE ROLE guardian_app LOGIN PASSWORD 'test_app' NOBYPASSRLS;

GRANT CONNECT ON DATABASE guardian TO guardian_app;
GRANT USAGE ON SCHEMA public TO guardian_app;
