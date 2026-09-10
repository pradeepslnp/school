-- V17 — Bulk student import (MOD-03, feature STU-002 / screen A-12)
--
-- See docs/03-database/tables/MOD-03-04-students-guardians.md and
-- docs/04-api/STUDENTS_GUARDIANS_API.md §POST /students/import.
--
-- One upload of a spreadsheet becomes one row in student_import_jobs, plus one row in
-- student_import_row_errors for every line that could not be enrolled. The office re-downloads
-- the failed lines, corrects them, and re-uploads a small file (PERSONAS.md, Fatima).
--
-- Two properties, visible throughout and matching the rest of this schema:
--
--   * Both tables are append-only. A job records what a past import did; changing it would
--     rewrite history. There is no UPDATE grant and no DELETE path — the same discipline V4
--     applies to students and guardian links.
--   * Row-level security is applied HERE, in the same migration that creates the tables — never
--     in a follow-up (V1 sets the precedent). A table that exists for even one deploy without a
--     policy was readable across tenants for that deploy.

-- ---------------------------------------------------------------------------------------
-- student_import_jobs — one per uploaded file
--
-- status is COMPLETED for a file that was parsed and processed (whatever the per-row outcome)
-- and FAILED for one that could not be read at all — an unparseable upload, or a column layout
-- with no recognisable header. The column is kept rather than implied so that a later move to
-- asynchronous processing (a PROCESSING state) is an additive change, not a schema break.
-- ---------------------------------------------------------------------------------------
CREATE TABLE student_import_jobs (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id      UUID         NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    -- The operator who uploaded the file. No FK: users may be deactivated while an import
    -- record must remain readable, the same reasoning audit records use for their actor.
    uploaded_by    UUID         NOT NULL,
    uploaded_role  VARCHAR(64)  NOT NULL,
    -- The original filename, shown back to the operator so they can tell two imports apart.
    -- Not trusted as a path — it is a label.
    file_name      VARCHAR(255) NOT NULL,
    status         VARCHAR(24)  NOT NULL,
    total_rows     INTEGER      NOT NULL DEFAULT 0,
    success_count  INTEGER      NOT NULL DEFAULT 0,
    error_count    INTEGER      NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    completed_at   TIMESTAMPTZ,

    CONSTRAINT ck_student_import_jobs_status
        CHECK (status IN ('COMPLETED', 'FAILED')),
    CONSTRAINT ck_student_import_jobs_counts
        CHECK (total_rows >= 0 AND success_count >= 0 AND error_count >= 0
               AND success_count + error_count <= total_rows)
);

-- The register screen lists a school's recent imports newest-first.
CREATE INDEX idx_student_import_jobs_school
    ON student_import_jobs (tenant_id, school_id, created_at DESC);

-- ---------------------------------------------------------------------------------------
-- student_import_row_errors — one per line that was not enrolled
--
-- row_number is the line number in the uploaded file as the operator sees it in a spreadsheet
-- (the header is row 1, the first data line is row 2), so "Row 17" in the console points at the
-- line they need to fix.
-- ---------------------------------------------------------------------------------------
CREATE TABLE student_import_row_errors (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    job_id      UUID         NOT NULL REFERENCES student_import_jobs (id) ON DELETE RESTRICT,
    row_number  INTEGER      NOT NULL,
    -- The offending column, or null when the whole row is the problem (too few fields).
    field       VARCHAR(64),
    error_code  VARCHAR(64)  NOT NULL,
    -- A fallback human message in the tenant's default locale. messageKey is derived from
    -- error_code on the wire (BR-CFG-005); this column is not the authority for display.
    message     VARCHAR(500) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_student_import_row_errors_job
    ON student_import_row_errors (tenant_id, job_id, row_number);

-- ---------------------------------------------------------------------------------------
-- Row-level security
--
-- Same shape as V1/V3/V4: ENABLE + FORCE, one FOR ALL policy carrying both USING and
-- WITH CHECK, NULLIF so an unset context yields no rows rather than an error.
-- ---------------------------------------------------------------------------------------
ALTER TABLE student_import_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_import_jobs FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON student_import_jobs
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE student_import_row_errors ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_import_row_errors FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON student_import_row_errors
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- Grants
--
-- SELECT and INSERT only. An import job is written once, when the file has finished
-- processing, and a row error is a fact about that run — neither is ever updated or deleted.
-- ---------------------------------------------------------------------------------------
GRANT SELECT, INSERT ON student_import_jobs        TO guardian_app;
GRANT SELECT, INSERT ON student_import_row_errors  TO guardian_app;
