-- V7 — Handover Verification Codes (MOD-09, minimal slice)
--
-- Backs screen P-12 (guardian-docs/05-ui/PARENT_APP.md § P-12 — Handover Verification) and
-- BR-HAND-002: at least one verification method must be enabled, and this table is the
-- QR / numeric-PIN method.
--
-- Scope, stated plainly: this is code ISSUANCE only — what the parent app calls so a
-- guardian has something to show the attendant. It deliberately does NOT implement:
--   * redemption/verification at the vehicle (BR-HAND-001, BR-HAND-004 through BR-HAND-007)
--   * the handover record itself, which references a boarding event's alight record
--     (BR-HAND-004) — there is no alight-record pipeline in this codebase yet
--   * override flows and custody-restriction refusal (BR-HAND-003, BR-HAND-006)
-- Those belong to the driver/attendant app and the rest of MOD-09 (boarding events,
-- reconciliation), neither of which this migration touches. Building the full module here
-- would be exactly the false completeness ENGINEERING_PRINCIPLES.md rules out.
--
-- Row-level security is applied HERE, in the same migration that creates the table.

-- ---------------------------------------------------------------------------------------
-- handover_verification_codes
--
-- One row per issued code. A guardian may hold at most one live (unredeemed, unexpired)
-- code per student — requesting again supersedes the previous one rather than leaving two
-- valid codes in circulation, which is the ordinary "I generated it, then reopened the
-- screen" case, not a suspicious one.
--
-- code is CHAR(6) numeric, matching the PARENT_APP.md mockup ("Code: 4 8 2 9 1 3") and
-- BR-HAND-002's PIN method. The QR payload the client renders is this same code — a second,
-- independent secret would be one more thing that can fail to match at the vehicle.
--
-- No soft-delete columns: an issued code is a safety-adjacent fact and stays (append-only,
-- same posture as absences and notifications). "Superseded" is expressed by
-- superseded_at, not by deleting the row.
-- ---------------------------------------------------------------------------------------
CREATE TABLE handover_verification_codes (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    student_id            UUID        NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    -- Who requested it. Always a guardian holding can_authorise_handover at issuance time
    -- (BR-GRD-006) — checked by the use case, not by a constraint here.
    requested_by_guardian_id UUID     NOT NULL REFERENCES guardians (id) ON DELETE RESTRICT,
    code                  CHAR(6)     NOT NULL,
    issued_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Short-lived by design: a code that outlives the pickup window is a code that can be
    -- reused by someone who saw a screenshot. 10 minutes matches "show this to the
    -- attendant" being a same-moment action, not something planned ahead.
    expires_at            TIMESTAMPTZ NOT NULL,
    -- Set when a later request replaces this code before it was used or expired. Distinct
    -- from redeemed_at, which the (unbuilt) attendant-side flow would set.
    superseded_at         TIMESTAMPTZ,
    redeemed_at           TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by            UUID,
    version               BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT ck_handover_codes_code_numeric CHECK (code ~ '^[0-9]{6}$'),
    CONSTRAINT ck_handover_codes_expiry       CHECK (expires_at > issued_at)
);

-- P-12's query: the caller's current live code for a student, if any.
CREATE INDEX idx_handover_codes_student_live
    ON handover_verification_codes (tenant_id, student_id, expires_at)
    WHERE superseded_at IS NULL AND redeemed_at IS NULL;

-- ---------------------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------------------
ALTER TABLE handover_verification_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE handover_verification_codes FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON handover_verification_codes
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- Grants
--
-- No DELETE and no UPDATE beyond superseding/redeeming — an issued code is evidence of who
-- asked for a release credential and when, which is exactly what BR-HAND-003's escalation
-- path would need to reconstruct if a handover were later disputed.
-- ---------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON handover_verification_codes TO guardian_app;
