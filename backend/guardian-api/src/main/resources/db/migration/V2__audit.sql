-- V2 — Audit (MOD-16)
--
-- Append-only, enforced by BOTH grants and a trigger. Two independent controls, because
-- the platform's evidentiary value rests entirely on this property (BR-AUD-001).
--
-- See docs/03-database/tables/MOD-16-17-audit-config.md.

CREATE TABLE audit_records (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID        NOT NULL,
    actor_id       UUID,
    actor_type     VARCHAR(24) NOT NULL,
    -- The role held AT THE TIME. Roles change; a record showing today's role for last
    -- year's action is misleading evidence (BR-AUD-003).
    actor_role     VARCHAR(32),
    action         VARCHAR(64) NOT NULL,
    -- Polymorphic reference with NO foreign key, deliberately: a subject may be archived
    -- or its table restructured while the audit trail must remain readable and intact.
    subject_type   VARCHAR(48) NOT NULL,
    subject_id     UUID        NOT NULL,
    reason         TEXT,
    source         VARCHAR(24) NOT NULL,
    correlation_id UUID,
    before_values  JSONB,
    after_values   JSONB,
    occurred_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_audit_actor_type
        CHECK (actor_type IN ('USER', 'SYSTEM', 'DEVICE', 'PLATFORM_OPERATOR')),
    CONSTRAINT ck_audit_source
        CHECK (source IN ('API', 'DEVICE', 'JOB', 'PLATFORM_OPS'))
);

-- No updated_at, no version, no soft delete: the row never changes.

CREATE INDEX idx_audit_subject
    ON audit_records (tenant_id, subject_type, subject_id, occurred_at DESC);
CREATE INDEX idx_audit_actor
    ON audit_records (tenant_id, actor_id, occurred_at DESC);
CREATE INDEX idx_audit_correlation
    ON audit_records (correlation_id);
-- Serves the override register (AUD-003) — the report a school reviews when a parent
-- questions a handover.
CREATE INDEX idx_audit_overrides
    ON audit_records (tenant_id, action, occurred_at DESC) WHERE reason IS NOT NULL;

-- ---------------------------------------------------------------------------------------
-- data_access_records — who read which child's data (BR-IAM-012)
--
-- Separate table from audit_records: much higher volume, different retention, different
-- indexing. This is what makes insider misuse detectable rather than merely prohibited.
-- ---------------------------------------------------------------------------------------
CREATE TABLE data_access_records (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID        NOT NULL,
    actor_id       UUID        NOT NULL,
    actor_role     VARCHAR(32) NOT NULL,
    student_id     UUID        NOT NULL,
    access_type    VARCHAR(24) NOT NULL,
    purpose        VARCHAR(64),
    record_count   INTEGER,
    correlation_id UUID,
    occurred_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_data_access_type
        CHECK (access_type IN ('VIEW', 'LIST', 'EXPORT', 'REPORT'))
);

CREATE INDEX idx_data_access_student ON data_access_records (tenant_id, student_id, occurred_at DESC);
CREATE INDEX idx_data_access_actor   ON data_access_records (tenant_id, actor_id, occurred_at DESC);

-- ---------------------------------------------------------------------------------------
-- Append-only enforcement — control 1: trigger
-- ---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION reject_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Table % is append-only (BR-AUD-001 / BR-BOARD-001)', TG_TABLE_NAME
        USING ERRCODE = 'raise_exception';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_records_append_only
    BEFORE UPDATE OR DELETE ON audit_records
    FOR EACH ROW EXECUTE FUNCTION reject_mutation();

CREATE TRIGGER trg_data_access_records_append_only
    BEFORE UPDATE OR DELETE ON data_access_records
    FOR EACH ROW EXECUTE FUNCTION reject_mutation();

-- ---------------------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------------------
ALTER TABLE audit_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_records FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON audit_records
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE data_access_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_access_records FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON data_access_records
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- Append-only enforcement — control 2: grants
--
-- Stronger than the trigger, and stronger than any application-level convention: the
-- runtime role simply has no UPDATE or DELETE privilege to exercise.
-- ---------------------------------------------------------------------------------------
GRANT SELECT, INSERT ON audit_records, data_access_records TO guardian_app;
