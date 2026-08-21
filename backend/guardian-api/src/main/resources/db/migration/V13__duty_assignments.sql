-- V13 — Duty Assignments (MOD-06, feature STF-004)
--
-- Deferred out of V9__staff.sql deliberately (see that file's own comment): duty_assignments
-- has a NOT NULL foreign key to routes(id), and no route-owning module (MOD-07) existed yet.
-- guardian-routes now does, so this table can finally be created against a real routes table
-- rather than a nullable FK that would contradict MOD-05-06-fleet-staff.md's documented schema.
--
-- This is the *standing* crew roster — which staff normally run which route. Actual crew for a
-- specific trip lives in trip_staff (MOD-08, not yet built), kept separate so a one-off
-- substitution (BR-STAFF-006) does not rewrite the standing roster.

CREATE TABLE duty_assignments (
    id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    staff_id           UUID        NOT NULL REFERENCES transport_staff (id) ON DELETE RESTRICT,
    route_id           UUID        NOT NULL REFERENCES routes (id) ON DELETE RESTRICT,
    role               VARCHAR(24) NOT NULL,
    -- Null means both directions — most crew run the same route morning and afternoon.
    direction          VARCHAR(16),
    effective_from     DATE        NOT NULL DEFAULT CURRENT_DATE,
    effective_until    DATE,
    is_active          BOOLEAN     NOT NULL DEFAULT true,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by         UUID,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by         UUID,
    version            BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT ck_duty_role      CHECK (role IN ('DRIVER', 'ATTENDANT')),
    CONSTRAINT ck_duty_direction CHECK (direction IS NULL OR direction IN ('PICKUP', 'DROP'))
);

CREATE INDEX idx_duty_assignments_route ON duty_assignments (tenant_id, route_id) WHERE is_active;
CREATE INDEX idx_duty_assignments_staff ON duty_assignments (tenant_id, staff_id) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- Row-level security — see V1__baseline_tenancy.sql for the rationale of each clause.
-- ---------------------------------------------------------------------------------------
ALTER TABLE duty_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE duty_assignments FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON duty_assignments
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON duty_assignments TO guardian_app;
