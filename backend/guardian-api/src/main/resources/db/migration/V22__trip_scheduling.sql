-- V22 — Trip scheduling data (MOD-07 timetable, consumed by MOD-08 trip generation)
--
-- WHY THIS EXISTS
--
-- BR-TRIP-011 requires trips to be "generated in advance for scheduled operating days", with
-- "school holidays and non-operating days" suppressing generation. Every input that rule needs
-- was already in the schema except two, and their absence is why no trip row has ever been
-- created by anything other than the demo seed:
--
--   * which days of the week a route runs, and
--   * which dates a school does not operate (or exceptionally does).
--
-- Both are added here. Note what is deliberately NOT added:
--
--   * No per-route start time. `stops.scheduled_pickup_time` / `scheduled_drop_time` already
--     carry the timetable, and a trip's start is the earliest stop time on that run. A second
--     place to state the same fact is a second place for it to drift (ENGINEERING_PRINCIPLES §DRY).
--   * No "directions this route runs" column. A route runs a PICKUP if any active stop carries a
--     `scheduled_pickup_time`, and a DROP likewise — the timetable already says so. Adding a flag
--     would let a route be marked as running a direction it has no times for.
--
-- The trips table itself is unchanged: V5 already models it correctly, including the
-- UNIQUE (tenant_id, route_id, service_date, direction) constraint that makes generation
-- idempotent under concurrency (MaterialiseTripsUseCase relies on it, ON CONFLICT DO NOTHING).

-- ---------------------------------------------------------------------------------------
-- Operating days per route (MOD-07)
-- ---------------------------------------------------------------------------------------
--
-- Stored as a comma-separated list of three-letter day codes rather than seven booleans or a
-- bitmask: it is read far more often than it is computed with, and 'MON,TUE,WED,THU,FRI' is
-- legible in a psql session during an incident, which a bitmask of 31 is not.
--
-- The default is the five-day school week — the overwhelmingly common case, and it means every
-- route that already exists becomes schedulable without a data migration or an operator visiting
-- each one. A route that runs Saturdays is an edit, not a prerequisite.
ALTER TABLE routes
    ADD COLUMN operating_days VARCHAR(27) NOT NULL DEFAULT 'MON,TUE,WED,THU,FRI';

ALTER TABLE routes
    ADD CONSTRAINT ck_routes_operating_days CHECK (
        operating_days ~ '^(MON|TUE|WED|THU|FRI|SAT|SUN)(,(MON|TUE|WED|THU|FRI|SAT|SUN))*$');

COMMENT ON COLUMN routes.operating_days IS
    'Days of the week this route runs, e.g. MON,TUE,WED,THU,FRI (BR-TRIP-011). '
    'Order is not significant; the domain normalises.';

-- ---------------------------------------------------------------------------------------
-- School calendar exceptions (MOD-07)
-- ---------------------------------------------------------------------------------------
--
-- Two types, because a school calendar needs both directions:
--
--   HOLIDAY      — a date the school does not operate even though the weekday says it should.
--   WORKING_DAY  — a date the school DOES operate even though the weekday says it should not
--                  (a Saturday exam day, a make-up day after a closure). Without this, an
--                  operator's only way to run a Saturday would be to edit every route's
--                  operating_days and remember to change them back.
--
-- One row per school per date: a date is either an exception or it is not.
CREATE TABLE school_calendar_exceptions (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id      UUID         NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    exception_date DATE         NOT NULL,
    exception_type VARCHAR(16)  NOT NULL,
    -- Optional, but strongly encouraged: "why was there no bus on the 14th" is a question
    -- somebody asks three months later.
    reason         VARCHAR(255),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by     UUID,
    version        BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_school_calendar_exception UNIQUE (tenant_id, school_id, exception_date),
    CONSTRAINT ck_school_calendar_type CHECK (exception_type IN ('HOLIDAY', 'WORKING_DAY'))
);

CREATE INDEX idx_school_calendar_date
    ON school_calendar_exceptions (tenant_id, school_id, exception_date);

-- ---------------------------------------------------------------------------------------
-- Row-level security — see V1__baseline_tenancy.sql for the rationale of each clause.
-- ---------------------------------------------------------------------------------------
ALTER TABLE school_calendar_exceptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_calendar_exceptions FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON school_calendar_exceptions
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON school_calendar_exceptions TO guardian_app;

-- ---------------------------------------------------------------------------------------
-- Tenant enumeration for the generation job
-- ---------------------------------------------------------------------------------------
--
-- Trip generation is a background job: it runs on a timer with no request, no session, and
-- therefore no tenant. It has to visit every active organization in turn, and an ordinary
-- SELECT against `organizations` under RLS returns at most the one row matching app.tenant_id
-- — which, with no context set, is none.
--
-- Same mechanism as V11's org_code_exists and V12's list_organizations, and deliberately a
-- THIRD function rather than reuse of either: this one returns only the ids of ACTIVE
-- organizations and nothing else, so the widest thing a compromised caller could learn from it
-- is how many tenants exist. `list_organizations()` returns whole rows and is guarded in the
-- application layer by a literal SUPER_ADMIN check; a background job has no role to check, so
-- it gets a function narrow enough not to need one.
--
-- The job then sets tenant context per organization (TenantContext.runAs) and does all real
-- work under RLS like any other caller.
--
-- guardian_platform_ops already holds SELECT on organizations (V12); no further grant needed.
CREATE FUNCTION scheduling_active_tenant_ids()
    RETURNS TABLE (tenant_id UUID)
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
AS $$
    SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY id;
$$;

ALTER FUNCTION scheduling_active_tenant_ids() OWNER TO guardian_platform_ops;

REVOKE ALL ON FUNCTION scheduling_active_tenant_ids() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION scheduling_active_tenant_ids() TO guardian_app;

-- ---------------------------------------------------------------------------------------
-- Index supporting the driver's "my trips today" query and the generation existence check.
-- V5 already indexes (tenant_id, school_id, service_date); generation and the crew's day view
-- both query by route and date without knowing the school.
-- ---------------------------------------------------------------------------------------
CREATE INDEX idx_trips_route_date ON trips (tenant_id, route_id, service_date);
