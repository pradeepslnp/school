-- V5 — Fleet, Routes, Trips, Boarding (MOD-05, MOD-07, MOD-08, MOD-09)
--
-- See docs/03-database/tables/MOD-05-06-fleet-staff.md, MOD-07-routes.md, MOD-08-trips.md,
-- and MOD-09-boarding.md.
--
-- Scope: the tables the parent app's journey projection reads (ADR-0010) — a vehicle a
-- parent can name, the stop their child waits at, today's trip, the manifest that says who
-- was expected, and the boarding events that say what actually happened. The remainder of
-- MOD-05/06/08/09 (documents, staff credentials, duty assignment, handovers,
-- reconciliation) arrives with the driver app, which is where those tables are written.
--
-- Deliberately omitted for now, and why:
--   handovers, reconciliations   written only by the driver app (D-08, D-11)
--   position_history             partitioned, and live position is Redis (ADR-0004)
--   trip_manifest_amendments     needs the manifest-amend endpoint (MOD-08)
--
-- Row-level security is applied HERE, in the same migration that creates the tables.

-- ---------------------------------------------------------------------------------------
-- vehicles (MOD-05)
--
-- display_name is what the platform shows a parent — "Bus 12". Held separately from
-- registration_no on purpose: a registration number is an identifier for staff and
-- authorities, and putting it in a parent-facing notification tells a parent something they
-- did not ask for about a vehicle their child is on.
-- ---------------------------------------------------------------------------------------
CREATE TABLE vehicles (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id       UUID         NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    registration_no VARCHAR(32)  NOT NULL,
    display_name    VARCHAR(64)  NOT NULL,
    capacity        INTEGER      NOT NULL,
    status          VARCHAR(24)  NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      UUID,
    version         BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_vehicles_registration UNIQUE (tenant_id, registration_no),
    CONSTRAINT ck_vehicles_status   CHECK (status IN ('ACTIVE', 'MAINTENANCE', 'RETIRED')),
    CONSTRAINT ck_vehicles_capacity CHECK (capacity > 0)
);

CREATE INDEX idx_vehicles_school ON vehicles (tenant_id, school_id) WHERE status = 'ACTIVE';

-- ---------------------------------------------------------------------------------------
-- routes (MOD-07)
-- ---------------------------------------------------------------------------------------
CREATE TABLE routes (
    id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id          UUID         NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    code               VARCHAR(32)  NOT NULL,
    name               VARCHAR(255) NOT NULL,
    default_vehicle_id UUID         REFERENCES vehicles (id) ON DELETE SET NULL,
    -- Null means "use the tenant default" rather than "no threshold" (BR-ALERT-002).
    corridor_width_m   INTEGER,
    path_geometry      JSONB,
    is_active          BOOLEAN      NOT NULL DEFAULT true,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by         UUID,
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by         UUID,
    version            BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_routes_school_code UNIQUE (tenant_id, school_id, code)
);

CREATE INDEX idx_routes_school ON routes (tenant_id, school_id) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- stops (MOD-07)
--
-- `name` appears verbatim in parent notifications ("Boarded at Green Park"), so it is
-- parent-facing copy, not an internal label.
-- ---------------------------------------------------------------------------------------
CREATE TABLE stops (
    id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    route_id              UUID         NOT NULL REFERENCES routes (id) ON DELETE RESTRICT,
    sequence_no           INTEGER      NOT NULL,
    name                  VARCHAR(255) NOT NULL,
    latitude              NUMERIC(9,6) NOT NULL,
    longitude             NUMERIC(9,6) NOT NULL,
    geofence_radius_m     INTEGER      NOT NULL,
    -- TIME, not TIMESTAMPTZ: a schedule is a wall-clock fact in the school's zone that
    -- survives daylight saving, where an instant would drift by an hour twice a year.
    scheduled_pickup_time TIME,
    scheduled_drop_time   TIME,
    landmark              VARCHAR(255),
    is_active             BOOLEAN      NOT NULL DEFAULT true,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by            UUID,
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by            UUID,
    version               BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_stops_route_sequence UNIQUE (tenant_id, route_id, sequence_no),
    CONSTRAINT ck_stops_sequence  CHECK (sequence_no > 0),
    CONSTRAINT ck_stops_latitude  CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT ck_stops_longitude CHECK (longitude BETWEEN -180 AND 180),
    -- Same floor and ceiling as schools (BR-ROUTE-003, BR-CFG-003): below it GPS drift means
    -- arrival is never detected, above it geofences overlap and arrival stops meaning anything.
    CONSTRAINT ck_stops_geofence  CHECK (geofence_radius_m BETWEEN 20 AND 2000)
);

CREATE INDEX idx_stops_route ON stops (tenant_id, route_id, sequence_no) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- route_student_assignments (MOD-07)
--
-- Per direction, because a child collected from home in the morning is frequently dropped
-- somewhere else in the afternoon — a grandparent, an after-school class. One assignment for
-- both directions would quietly make the afternoon stop wrong.
-- ---------------------------------------------------------------------------------------
CREATE TABLE route_student_assignments (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    route_id   UUID        NOT NULL REFERENCES routes (id) ON DELETE RESTRICT,
    stop_id    UUID        NOT NULL REFERENCES stops (id) ON DELETE RESTRICT,
    student_id UUID        NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    direction  VARCHAR(16) NOT NULL,
    valid_from DATE        NOT NULL DEFAULT CURRENT_DATE,
    valid_to   DATE,
    is_active  BOOLEAN     NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by UUID,
    version    BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT ck_rsa_direction CHECK (direction IN ('PICKUP', 'DROP'))
);

-- One active assignment per student per direction: two would make "which stop is my child
-- waiting at" ambiguous, and the answer is a safety fact.
CREATE UNIQUE INDEX uq_rsa_student_direction
    ON route_student_assignments (tenant_id, student_id, direction) WHERE is_active;

CREATE INDEX idx_rsa_route ON route_student_assignments (tenant_id, route_id) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- trips (MOD-08) — the operational centre; every safety event anchors to a trip
--
-- school_id is denormalised from route deliberately: nearly every trip query filters by
-- school and date, and joining through routes for it costs a join on the hottest read.
-- ---------------------------------------------------------------------------------------
CREATE TABLE trips (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id            UUID        NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    route_id             UUID        NOT NULL REFERENCES routes (id) ON DELETE RESTRICT,
    -- Null until the trip starts: the vehicle is chosen at start, and recording an intended
    -- one as fact would misreport which bus a child actually boarded.
    vehicle_id           UUID        REFERENCES vehicles (id) ON DELETE RESTRICT,
    service_date         DATE        NOT NULL,
    direction            VARCHAR(16) NOT NULL,
    status               VARCHAR(24) NOT NULL DEFAULT 'SCHEDULED',
    scheduled_start_time TIME,
    started_at           TIMESTAMPTZ,
    ended_at             TIMESTAMPTZ,
    closed_at            TIMESTAMPTZ,
    -- Device clock, kept for reference only. started_at is server time, because a driver
    -- phone with a wrong clock must not be able to move a safety record in time.
    device_started_at    TIMESTAMPTZ,
    cancelled_reason     TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by           UUID,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by           UUID,
    version              BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT uq_trips_route_date_direction
        UNIQUE (tenant_id, route_id, service_date, direction),
    CONSTRAINT ck_trips_direction CHECK (direction IN ('PICKUP', 'DROP')),
    CONSTRAINT ck_trips_status CHECK (
        status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CLOSED', 'CANCELLED'))
);

CREATE INDEX idx_trips_school_date ON trips (tenant_id, school_id, service_date);
CREATE INDEX idx_trips_active      ON trips (tenant_id, school_id) WHERE status = 'IN_PROGRESS';

-- ---------------------------------------------------------------------------------------
-- trip_manifests 🔴 (MOD-08)
--
-- Materialised at trip start and immutable thereafter (BR-TRIP-003 🔴): active route
-- assignments for this route and direction, MINUS declared absences for the date, WHERE the
-- student is enrolled. Post-start changes are amendments, never edits.
--
-- student_name_snapshot is the name as at materialisation. A manifest is evidence of who was
-- expected on a vehicle on a date; resolving the name live would silently rewrite that
-- evidence when a student's name later changes.
-- ---------------------------------------------------------------------------------------
CREATE TABLE trip_manifests (
    id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    trip_id               UUID         NOT NULL REFERENCES trips (id) ON DELETE RESTRICT,
    student_id            UUID         NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    expected_stop_id      UUID         NOT NULL REFERENCES stops (id) ON DELETE RESTRICT,
    student_name_snapshot VARCHAR(255) NOT NULL,
    sequence_no           INTEGER      NOT NULL,
    status                VARCHAR(24)  NOT NULL DEFAULT 'EXPECTED',
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    version               BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_trip_manifests UNIQUE (tenant_id, trip_id, student_id),
    CONSTRAINT ck_trip_manifests_status CHECK (
        status IN ('EXPECTED', 'BOARDED', 'ALIGHTED', 'NO_SHOW', 'ABSENT'))
);

CREATE INDEX idx_trip_manifests_trip    ON trip_manifests (tenant_id, trip_id, sequence_no);
-- The parent dashboard's entry point into trip state: "is my child on a manifest today".
CREATE INDEX idx_trip_manifests_student ON trip_manifests (tenant_id, student_id);

-- ---------------------------------------------------------------------------------------
-- boarding_events 🔴 (MOD-09) — APPEND-ONLY
--
-- The most safety-critical table in the platform. A correction is a new row pointing at the
-- row it corrects (corrects_event_id), never an UPDATE: "the record was wrong and here is
-- the fix" and "the record always said this" must stay distinguishable, and only the first
-- of those survives an in-place edit.
--
-- Append-only is enforced by the GRANT at the bottom of this file — SELECT and INSERT only,
-- no UPDATE, no DELETE — so it holds even for code that forgets (BR-AUD-001, BR-BOARD-*).
--
-- client_event_id is globally unique and is the idempotency key. The driver app is
-- offline-first (ADR-0008) and retries by design; without this a child would be recorded as
-- boarding twice, and trip-close reconciliation would then be wrong.
-- ---------------------------------------------------------------------------------------
CREATE TABLE boarding_events (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    trip_id             UUID        NOT NULL REFERENCES trips (id) ON DELETE RESTRICT,
    student_id          UUID        NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    -- Null when boarding or alighting at the school itself rather than at a route stop.
    stop_id             UUID        REFERENCES stops (id) ON DELETE RESTRICT,
    event_type          VARCHAR(16) NOT NULL,
    verification_method VARCHAR(32) NOT NULL,
    actor_id            UUID        NOT NULL,
    -- The role as held AT THE TIME (BR-AUD-003). Roles change; a record showing today's role
    -- for last year's action is misleading evidence.
    actor_role          VARCHAR(32) NOT NULL,
    client_event_id     UUID        NOT NULL,
    corrects_event_id   UUID        REFERENCES boarding_events (id) ON DELETE RESTRICT,
    is_override         BOOLEAN     NOT NULL DEFAULT false,
    override_reason     TEXT,
    -- Device clock. occurred_at is what the driver saw; recorded_at is when the server heard
    -- about it. On an offline-first client those differ by hours, and both matter.
    occurred_at         TIMESTAMPTZ NOT NULL,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    clock_skew_seconds  INTEGER,
    sync_state          VARCHAR(16) NOT NULL DEFAULT 'SYNCED',

    CONSTRAINT uq_boarding_client_event UNIQUE (client_event_id),
    CONSTRAINT ck_boarding_type CHECK (event_type IN ('BOARD', 'ALIGHT')),
    CONSTRAINT ck_boarding_verification CHECK (
        verification_method IN ('QR_SCAN', 'CARD', 'MANUAL', 'OTP', 'VISUAL')),
    CONSTRAINT ck_boarding_sync CHECK (sync_state IN ('SYNCED', 'FLAGGED_FOR_REVIEW')),
    -- An override without a reason is an unexplained safety decision (BR-AUD-004).
    CONSTRAINT ck_boarding_override_reason CHECK (
        NOT is_override OR (override_reason IS NOT NULL AND length(btrim(override_reason)) > 0))
);

CREATE INDEX idx_boarding_trip    ON boarding_events (tenant_id, trip_id, occurred_at);
-- Journey history (P-05) reads this: one student, newest first.
CREATE INDEX idx_boarding_student ON boarding_events (tenant_id, student_id, occurred_at DESC);

-- ---------------------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------------------
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON vehicles
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON routes
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE stops FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON stops
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE route_student_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_student_assignments FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON route_student_assignments
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON trips
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE trip_manifests ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_manifests FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON trip_manifests
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE boarding_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE boarding_events FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON boarding_events
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- Grants
--
-- boarding_events receives SELECT and INSERT ONLY. That absence is the append-only control
-- (BR-AUD-001): a correction has to be a compensating row because the database will not
-- accept anything else. Adding UPDATE here later would silently remove that guarantee.
-- ---------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON vehicles                  TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON routes                    TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON stops                     TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON route_student_assignments TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON trips                     TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON trip_manifests            TO guardian_app;
GRANT SELECT, INSERT                ON boarding_events    TO guardian_app;
