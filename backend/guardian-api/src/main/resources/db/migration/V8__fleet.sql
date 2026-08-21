-- V8 — Fleet (MOD-05)
--
-- `vehicles` already exists (V5__fleet_routes_trips_boarding.sql). That migration created it
-- deliberately narrow — scoped to only what the parent app's journey projection reads — and its
-- own header comment defers "the remainder of MOD-05/06/08/09 ... arrives with the driver app,
-- which is where those tables are written." This migration is that remainder for MOD-05: it
-- completes `vehicles` with ALTER statements (a second CREATE TABLE vehicles would fail outright
-- — the table is already there) and adds the two tables V5 does not touch: vehicle_documents and
-- devices.
--
-- Row-level security for `vehicles` was already applied in V5; it is not re-applied here.
--
-- See guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md and
-- guardian-docs/03-database/RLS_POLICIES.md.

-- ---------------------------------------------------------------------------------------
-- vehicles — completing the columns MOD-05-06-fleet-staff.md documents but V5 deferred
-- ---------------------------------------------------------------------------------------

-- V5 named this column `capacity`; the documented spec and every fleet-side consumer (this
-- module's domain and JPA mapping) name it `seating_capacity`. A rename, not a second column:
-- guardian-parent's read model (JdbcParentReadModel) never reads this column — only
-- display_name — so nothing downstream breaks, and carrying two names for one fact would be
-- worse than a rename.
ALTER TABLE vehicles RENAME COLUMN capacity TO seating_capacity;

-- Added without a DEFAULT: V8 runs before V900__demo_data.sql (Flyway orders by version, and
-- 900 > 8) in every environment that follows the migration chain, so `vehicles` is empty at
-- this point and NOT NULL can be applied directly — no backfill UPDATE is needed or wanted here.
-- V900__demo_data.sql's INSERT is updated in this same change to supply vehicle_type explicitly.
ALTER TABLE vehicles ADD COLUMN vehicle_type VARCHAR(24) NOT NULL DEFAULT 'BUS';
ALTER TABLE vehicles ALTER COLUMN vehicle_type DROP DEFAULT;
ALTER TABLE vehicles ADD COLUMN vendor_name VARCHAR(255);

ALTER TABLE vehicles ADD CONSTRAINT ck_vehicles_type CHECK (vehicle_type IN ('BUS', 'VAN', 'MINIBUS'));

-- ---------------------------------------------------------------------------------------
-- vehicle_documents — compliance artefacts; expiry blocks trip assignment (BR-FLEET-002 🔴)
-- ---------------------------------------------------------------------------------------
CREATE TABLE vehicle_documents (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    vehicle_id      UUID         NOT NULL REFERENCES vehicles (id) ON DELETE RESTRICT,
    -- Free-form against region reference data, not a database enum (ADR-0007). Registration,
    -- fitness, insurance, and permit types differ by country; a code enum here would mean a
    -- code change to onboard a new market.
    document_type   VARCHAR(48)  NOT NULL,
    document_number VARCHAR(128),
    issued_on       DATE,
    expires_on      DATE         NOT NULL,
    is_mandatory    BOOLEAN      NOT NULL,
    file_ref        VARCHAR(255),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      UUID,
    version         BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT ck_vehicle_documents_dates CHECK (issued_on IS NULL OR expires_on > issued_on)
);

CREATE INDEX idx_vehicle_documents_expiry ON vehicle_documents (tenant_id, expires_on)
    WHERE is_mandatory;

-- ---------------------------------------------------------------------------------------
-- devices — GPS tracking devices (ADR-0004), optionally assigned to a vehicle
-- ---------------------------------------------------------------------------------------
CREATE TABLE devices (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    vehicle_id        UUID         REFERENCES vehicles (id) ON DELETE RESTRICT,
    device_identifier VARCHAR(128) NOT NULL,
    vendor_code       VARCHAR(48)  NOT NULL,
    credential_hash   VARCHAR(255) NOT NULL,
    last_seen_at      TIMESTAMPTZ,
    is_active         BOOLEAN      NOT NULL DEFAULT true,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by        UUID,
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by        UUID,
    version           BIGINT       NOT NULL DEFAULT 0,

    -- Globally unique, not scoped to tenant_id: ingestion resolves the device before it knows
    -- the tenant (guardian-docs/02-system-design/REALTIME_TRACKING_DESIGN.md).
    CONSTRAINT uq_devices_identifier UNIQUE (device_identifier)
);

-- BR-FLEET-004 🔴, enforced structurally: at most one *active* device per vehicle. Two devices
-- reporting for one bus would produce contradictory positions.
--
-- A partial unique index rather than a table constraint: PostgreSQL has no
-- `UNIQUE (…) WHERE …`, and the predicate is the whole point — a vehicle whose device is
-- replaced keeps the old row with is_active = false, which a plain unique constraint on
-- (tenant_id, vehicle_id) would reject.
CREATE UNIQUE INDEX uq_devices_vehicle_active ON devices (tenant_id, vehicle_id)
    WHERE is_active;

CREATE INDEX idx_devices_tenant ON devices (tenant_id) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- Row-level security — vehicle_documents and devices only. vehicles already has its policy
-- from V5. See V1__baseline_tenancy.sql for the rationale of each clause.
-- ---------------------------------------------------------------------------------------

ALTER TABLE vehicle_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_documents FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON vehicle_documents
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices FORCE  ROW LEVEL SECURITY;

-- Same policy shape as every other tenant-scoped table, per RLS_POLICIES.md's table list
-- ("Fleet: vehicles · vehicle_documents · devices").
--
-- OPEN QUESTION, left to MOD-10 (Tracking, not yet built): device_identifier is deliberately
-- global (see the unique constraint above) so ingestion can resolve a device before it knows
-- the tenant — but this policy means a lookup with no tenant context set returns zero rows,
-- same as any other tenant-scoped table. How the ingestion pipeline learns a tenant_id to set
-- before its first tenant-scoped read is not addressed by REALTIME_TRACKING_DESIGN.md as it
-- stands today and must be resolved — via a bounded, audited platform-operations-style path
-- (BR-TEN-004), not by adding a code path that turns RLS off — before MOD-10 ingests a single
-- position. Recorded here rather than guessed at, so it is not silently designed twice.
CREATE POLICY tenant_isolation ON devices
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- vehicles was already granted in V5; adding columns to an existing table does not require
-- re-granting.
GRANT SELECT, INSERT, UPDATE, DELETE
    ON vehicle_documents, devices
    TO guardian_app;
