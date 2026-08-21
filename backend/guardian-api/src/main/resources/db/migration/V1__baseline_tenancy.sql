-- V1 — Tenancy baseline (MOD-01)
--
-- Reference implementation for every later migration. Note that row-level security is
-- applied HERE, in the same migration that creates the tables — never in a follow-up.
-- A table that exists for even one deploy without a policy is a table that was readable
-- across tenants for that deploy.
--
-- See docs/03-database/tables/MOD-01-tenancy.md and docs/03-database/RLS_POLICIES.md.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------------------
-- organizations — the tenant itself
-- ---------------------------------------------------------------------------------------
CREATE TABLE organizations (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(32) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    region_profile_code VARCHAR(32) NOT NULL,
    status              VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
    contact_email       VARCHAR(255),
    contact_phone       VARCHAR(32),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by          UUID,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by          UUID,
    version             BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT uq_organizations_code   UNIQUE (code),
    CONSTRAINT ck_organizations_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED'))
);

CREATE INDEX idx_organizations_active ON organizations (status) WHERE status = 'ACTIVE';

-- ---------------------------------------------------------------------------------------
-- schools
-- ---------------------------------------------------------------------------------------
CREATE TABLE schools (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    organization_id   UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    code              VARCHAR(32)  NOT NULL,
    name              VARCHAR(255) NOT NULL,
    -- NOT NULL deliberately: every displayed time depends on it (BR-CFG-006), and a
    -- default to server time would be silently wrong for any school in another zone.
    timezone          VARCHAR(64)  NOT NULL,
    latitude          NUMERIC(9,6) NOT NULL,
    longitude         NUMERIC(9,6) NOT NULL,
    geofence_radius_m INTEGER      NOT NULL,
    status            VARCHAR(24)  NOT NULL DEFAULT 'ACTIVE',
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by        UUID,
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by        UUID,
    version           BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_schools_org_code UNIQUE (tenant_id, organization_id, code),
    CONSTRAINT ck_schools_status   CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_schools_latitude  CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT ck_schools_longitude CHECK (longitude BETWEEN -180 AND 180),
    -- BR-ROUTE-003 / BR-CFG-003: the platform floor and ceiling. Below the floor GPS drift
    -- means arrival is never detected; above the ceiling geofences overlap and arrival
    -- events stop meaning anything. A tenant may tune within the window, never outside it.
    CONSTRAINT ck_schools_geofence CHECK (geofence_radius_m BETWEEN 20 AND 2000)
);

CREATE INDEX idx_schools_tenant_org ON schools (tenant_id, organization_id);
CREATE INDEX idx_schools_active     ON schools (tenant_id, organization_id) WHERE status = 'ACTIVE';

-- ---------------------------------------------------------------------------------------
-- branches — optional subdivision (ADR-0002)
-- ---------------------------------------------------------------------------------------
CREATE TABLE branches (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id  UUID         NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    code       VARCHAR(32)  NOT NULL,
    name       VARCHAR(255) NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by UUID,
    version    BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_branches_school_code UNIQUE (tenant_id, school_id, code)
);

CREATE INDEX idx_branches_school ON branches (tenant_id, school_id) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- school_calendars — drives trip generation (BR-TRIP-011)
-- ---------------------------------------------------------------------------------------
CREATE TABLE school_calendars (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id     UUID        NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    calendar_date DATE        NOT NULL,
    day_type      VARCHAR(24) NOT NULL,
    notes         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by    UUID,
    version       BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT uq_school_calendars_date UNIQUE (tenant_id, school_id, calendar_date),
    CONSTRAINT ck_school_calendars_type
        CHECK (day_type IN ('OPERATING', 'HOLIDAY', 'EXAM', 'SPECIAL'))
);

CREATE INDEX idx_school_calendars_lookup
    ON school_calendars (tenant_id, school_id, calendar_date);

-- ---------------------------------------------------------------------------------------
-- Row-level security
--
-- Four details, each of which is load-bearing:
--   FORCE            without it the table owner bypasses the policy entirely
--   WITH CHECK       USING alone protects reads but permits WRITING into another tenant
--   current_setting(..., true)  returns NULL instead of erroring when the GUC was never
--                    set in this session
--   NULLIF(..., '')  once SET LOCAL has run and the transaction ends, the GUC is left as
--                    an EMPTY STRING rather than unset — and ''::uuid raises
--                    "invalid input syntax for type uuid", turning a request without
--                    tenant context into a 500 instead of an empty result. NULLIF maps
--                    both shapes to NULL, and `tenant_id = NULL` is never true, so an
--                    unset context means no access rather than an error
--   FOR ALL          one policy, rather than four that can drift apart
-- ---------------------------------------------------------------------------------------

-- organizations is the tenant table itself, so its policy compares id, not tenant_id.
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON organizations
    FOR ALL
    USING      (id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON schools
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON branches
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE school_calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_calendars FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON school_calendars
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON organizations, schools, branches, school_calendars
    TO guardian_app;
