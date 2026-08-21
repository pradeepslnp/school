-- V9 — Transport Staff (MOD-06)
--
-- transport_staff and staff_credentials, per guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md.
-- duty_assignments is deliberately NOT included: it has a NOT NULL foreign key to routes(id),
-- and no route-owning module (MOD-07) exists yet in this codebase to reference. Adding it now
-- would mean either a nullable FK that contradicts the documented schema, or a table that
-- cannot accept a single row until a later migration relaxes it — both worse than deferring the
-- whole table to the migration that ships alongside guardian-route. STF-004 stays out of
-- guardian-staff's traceability baseline until then.
--
-- Row-level security is applied HERE, in the same migration that creates the tables.
--
-- Unlike V8__fleet.sql, neither table here already exists — this module has no V5-style partial
-- predecessor (confirmed by grepping every prior migration for these table names before writing
-- this file).

-- ---------------------------------------------------------------------------------------
-- transport_staff
-- ---------------------------------------------------------------------------------------
CREATE TABLE transport_staff (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id           UUID         NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    -- Null until the person's account is activated (MOD-02) — a staff record can exist before
    -- the person has signed in once.
    user_id             UUID         REFERENCES users (id) ON DELETE SET NULL,
    staff_type          VARCHAR(24)  NOT NULL,
    employee_code       VARCHAR(64),
    first_name          VARCHAR(128) NOT NULL,
    last_name           VARCHAR(128) NOT NULL,
    phone               VARCHAR(32)  NOT NULL,
    photo_ref           VARCHAR(255),
    vendor_name         VARCHAR(255),
    verification_status VARCHAR(24)  NOT NULL DEFAULT 'PENDING',
    verified_until      DATE,
    is_active           BOOLEAN      NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by          UUID,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by          UUID,
    version             BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT ck_staff_type   CHECK (staff_type IN ('DRIVER', 'ATTENDANT')),
    CONSTRAINT ck_staff_verify CHECK (
        verification_status IN ('PENDING', 'VERIFIED', 'LAPSED', 'REJECTED')),
    -- BR-STAFF-002 🔴: prevents a permanently-verified staff member. A record claiming VERIFIED
    -- with no end date is a verification nobody will ever revisit — re-asserted in
    -- TransportStaff's constructor so a caller that never reaches the database cannot construct
    -- one either.
    CONSTRAINT ck_staff_verified_until CHECK (
        verification_status <> 'VERIFIED' OR verified_until IS NOT NULL),
    -- Unique within school where present (MOD-05-06-fleet-staff.md). A plain UNIQUE, not a
    -- partial index: Postgres treats NULL as distinct from every other NULL in a UNIQUE
    -- constraint, so vendor-supplied staff with no employee_code yet never collide with each
    -- other — "where present" falls out of standard NULL handling, no WHERE clause needed.
    CONSTRAINT uq_staff_school_employee_code UNIQUE (tenant_id, school_id, employee_code)
);

CREATE INDEX idx_staff_tenant_school ON transport_staff (tenant_id, school_id) WHERE is_active;
CREATE INDEX idx_staff_verification  ON transport_staff (tenant_id, verified_until)
    WHERE verification_status = 'VERIFIED';

-- ---------------------------------------------------------------------------------------
-- staff_credentials — licences and certifications; expiry blocks duty assignment (BR-STAFF-001 🔴)
-- ---------------------------------------------------------------------------------------
CREATE TABLE staff_credentials (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    staff_id          UUID         NOT NULL REFERENCES transport_staff (id) ON DELETE RESTRICT,
    -- Free-form against region reference data, not a database enum (ADR-0007) — same reasoning
    -- as vehicle_documents.document_type.
    credential_type   VARCHAR(48)  NOT NULL,
    credential_number VARCHAR(128),
    -- Licence class — checked against vehicle type (BR-STAFF-001).
    credential_class  VARCHAR(32),
    issued_on         DATE,
    expires_on        DATE         NOT NULL,
    is_mandatory      BOOLEAN      NOT NULL,
    file_ref          VARCHAR(255),
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by        UUID,
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by        UUID,
    version           BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT ck_staff_credentials_dates CHECK (issued_on IS NULL OR expires_on > issued_on)
);

CREATE INDEX idx_staff_credentials_expiry ON staff_credentials (tenant_id, expires_on)
    WHERE is_mandatory;

-- ---------------------------------------------------------------------------------------
-- Row-level security — see V1__baseline_tenancy.sql for the rationale of each clause.
-- ---------------------------------------------------------------------------------------

ALTER TABLE transport_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport_staff FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON transport_staff
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE staff_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_credentials FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON staff_credentials
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON transport_staff, staff_credentials
    TO guardian_app;
