-- V4 — Students & Guardians (MOD-03, MOD-04)
--
-- See docs/03-database/tables/MOD-03-04-students-guardians.md.
--
-- These tables answer the platform's most consequential question: may this adult collect
-- this child? Two things follow from that and are visible throughout:
--
--   * Rights are columns on guardian_student_links, never inferred from relationship_type
--     (BR-GRD-001). See the comment on that table.
--   * Row-level security is applied HERE, in the same migration that creates the tables —
--     never in a follow-up (V1 sets the precedent). A table that exists for even one deploy
--     without a policy was readable across tenants for that deploy.

-- ---------------------------------------------------------------------------------------
-- student_classes — grade/section within an academic year
-- ---------------------------------------------------------------------------------------
CREATE TABLE student_classes (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id     UUID        NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    grade         VARCHAR(32) NOT NULL,
    section       VARCHAR(32) NOT NULL,
    academic_year VARCHAR(16) NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by    UUID,
    version       BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT uq_student_classes
        UNIQUE (tenant_id, school_id, academic_year, grade, section)
);

CREATE INDEX idx_student_classes_school ON student_classes (tenant_id, school_id);

-- ---------------------------------------------------------------------------------------
-- students
-- ---------------------------------------------------------------------------------------
CREATE TABLE students (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    school_id         UUID         NOT NULL REFERENCES schools (id) ON DELETE RESTRICT,
    -- Null means school-wide rather than assigned to a branch (BR-TEN-005).
    branch_id         UUID         REFERENCES branches (id) ON DELETE RESTRICT,
    student_class_id  UUID         REFERENCES student_classes (id) ON DELETE RESTRICT,
    admission_no      VARCHAR(64)  NOT NULL,
    first_name        VARCHAR(128) NOT NULL,
    last_name         VARCHAR(128) NOT NULL,
    -- Drives self-release eligibility (BR-HAND-005), so it is data the handover check reads,
    -- not decoration on a profile screen.
    date_of_birth     DATE,
    -- A storage key, never a public URL. A guessable photo URL for a child is a safety
    -- problem, so images are served through an endpoint that checks permission and scope.
    photo_ref         VARCHAR(255),
    enrolment_status  VARCHAR(24)  NOT NULL DEFAULT 'ACTIVE',
    transport_eligible BOOLEAN     NOT NULL DEFAULT true,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by        UUID,
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by        UUID,
    version           BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_students_admission UNIQUE (tenant_id, school_id, admission_no),
    CONSTRAINT ck_students_enrolment CHECK (
        enrolment_status IN ('ACTIVE', 'INACTIVE', 'WITHDRAWN', 'TRANSFERRED'))
);

CREATE INDEX idx_students_tenant_school
    ON students (tenant_id, school_id) WHERE enrolment_status = 'ACTIVE';

-- ---------------------------------------------------------------------------------------
-- student_credentials — the boarding credential (STU-007)
--
-- Hashed like a password, and for the same reason: a leaked credential table would let
-- anyone forge a boarding scan. Lookup at the vehicle is by hash.
-- ---------------------------------------------------------------------------------------
CREATE TABLE student_credentials (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    student_id      UUID         NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    credential_type VARCHAR(24)  NOT NULL,
    credential_hash VARCHAR(255) NOT NULL,
    issued_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    revoked_at      TIMESTAMPTZ,
    is_active       BOOLEAN      NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    version         BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_student_credentials_hash UNIQUE (credential_hash),
    CONSTRAINT ck_student_credentials_type
        CHECK (credential_type IN ('QR', 'NFC_CARD', 'BARCODE'))
);

CREATE INDEX idx_student_credentials_student
    ON student_credentials (tenant_id, student_id) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- guardians
--
-- user_id is nullable on purpose. A guardian exists as a record — receiving SMS, authorised
-- for handover — before ever installing the app. Requiring an account first would exclude
-- exactly the parents the platform must reach (PRODUCT_PRINCIPLES.md §6).
-- ---------------------------------------------------------------------------------------
CREATE TABLE guardians (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    user_id    UUID         REFERENCES users (id) ON DELETE SET NULL,
    first_name VARCHAR(128) NOT NULL,
    last_name  VARCHAR(128) NOT NULL,
    -- The primary channel, and the reason SMS is the floor: not every guardian has an app.
    phone      VARCHAR(32)  NOT NULL,
    email      VARCHAR(255),
    photo_ref  VARCHAR(255),
    is_active  BOOLEAN      NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by UUID,
    version    BIGINT       NOT NULL DEFAULT 0
);

-- One guardian record per app account. Partial, because most guardians have no account.
CREATE UNIQUE INDEX uq_guardians_user
    ON guardians (tenant_id, user_id) WHERE user_id IS NOT NULL;

CREATE INDEX idx_guardians_phone ON guardians (tenant_id, phone) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- guardian_student_links 🔴 — the authorisation table for child collection
--
-- relationship_type records "mother", "father", "uncle". It is DESCRIPTIVE ONLY and confers
-- nothing. The four booleans below are authoritative (BR-GRD-001 🔴).
--
-- Inferring "father ⇒ may collect" would encode an assumption that is wrong in exactly the
-- cases where being wrong is most harmful: custody arrangements, and parents legally barred
-- from collection (BR-GRD-008).
--
-- can_authorise_handover DEFAULTs to false. Rights are granted deliberately, never by
-- default. BR-GRD-002 requires at least one guardian per student to hold it; PostgreSQL
-- cannot express a cross-row minimum as a constraint, so that one is enforced in the
-- application and carries a dedicated test. It is a documented deviation from "enforce
-- structurally", not an oversight.
-- ---------------------------------------------------------------------------------------
CREATE TABLE guardian_student_links (
    id                        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                 UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    guardian_id               UUID        NOT NULL REFERENCES guardians (id) ON DELETE RESTRICT,
    student_id                UUID        NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    relationship_type         VARCHAR(32) NOT NULL,
    can_view                  BOOLEAN     NOT NULL DEFAULT true,
    can_receive_notifications BOOLEAN     NOT NULL DEFAULT true,
    can_authorise_handover    BOOLEAN     NOT NULL DEFAULT false,
    can_declare_absence       BOOLEAN     NOT NULL DEFAULT false,
    is_primary                BOOLEAN     NOT NULL DEFAULT false,
    is_active                 BOOLEAN     NOT NULL DEFAULT true,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by                UUID,
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by                UUID,
    version                   BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT uq_guardian_student UNIQUE (tenant_id, guardian_id, student_id)
);

-- Serves the parent dashboard's scope join (BR-IAM-005): every parent read starts here.
CREATE INDEX idx_gsl_guardian ON guardian_student_links (tenant_id, guardian_id) WHERE is_active;
CREATE INDEX idx_gsl_student  ON guardian_student_links (tenant_id, student_id)  WHERE is_active;
CREATE INDEX idx_gsl_handover ON guardian_student_links (tenant_id, student_id)
    WHERE is_active AND can_authorise_handover;

-- ---------------------------------------------------------------------------------------
-- authorised_pickup_persons — an adult who may collect but is not a guardian (BR-GRD-005)
--
-- valid_until is NOT NULL: nominations always expire. A permanent nomination made once and
-- forgotten is a standing authorisation nobody reviews. Extending is an explicit act.
-- ---------------------------------------------------------------------------------------
CREATE TABLE authorised_pickup_persons (
    id                        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                 UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    student_id                UUID         NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    nominated_by_guardian_id  UUID         NOT NULL REFERENCES guardians (id) ON DELETE RESTRICT,
    full_name                 VARCHAR(255) NOT NULL,
    phone                     VARCHAR(32)  NOT NULL,
    relationship_note         VARCHAR(255),
    photo_ref                 VARCHAR(255),
    valid_from                TIMESTAMPTZ  NOT NULL,
    valid_until               TIMESTAMPTZ  NOT NULL,
    is_active                 BOOLEAN      NOT NULL DEFAULT true,
    revoked_at                TIMESTAMPTZ,
    revoked_by                UUID,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by                UUID,
    updated_at                TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by                UUID,
    version                   BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT ck_app_validity CHECK (valid_until > valid_from)
);

CREATE INDEX idx_app_student_valid
    ON authorised_pickup_persons (tenant_id, student_id, valid_from, valid_until)
    WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- custody_restrictions 🔴 — overrides everything above (BR-GRD-008, BR-HAND-006)
--
-- Evaluated before any handover and before any visibility check: a restriction beats an
-- active guardian link granting can_authorise_handover.
--
-- Visible only to PERM-CUSTODY-RESTRICTION-MANAGE — never to the restricted person, and
-- never in any guardian-facing response. The parent app has no screen for this and must
-- never gain one (docs/05-ui/PARENT_APP.md).
-- ---------------------------------------------------------------------------------------
CREATE TABLE custody_restrictions (
    id                     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID         NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    student_id             UUID         NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    restricted_guardian_id UUID         REFERENCES guardians (id) ON DELETE RESTRICT,
    restricted_person_name VARCHAR(255),
    restriction_type       VARCHAR(32)  NOT NULL,
    reason                 TEXT         NOT NULL,
    effective_from         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    effective_until        TIMESTAMPTZ,
    is_active              BOOLEAN      NOT NULL DEFAULT true,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by             UUID,
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by             UUID,
    version                BIGINT       NOT NULL DEFAULT 0,

    CONSTRAINT ck_custody_subject CHECK (
        restricted_guardian_id IS NOT NULL OR restricted_person_name IS NOT NULL),
    CONSTRAINT ck_custody_type CHECK (
        restriction_type IN ('NO_HANDOVER', 'NO_VISIBILITY', 'FULL'))
);

CREATE INDEX idx_custody_student ON custody_restrictions (tenant_id, student_id) WHERE is_active;

-- ---------------------------------------------------------------------------------------
-- Row-level security
--
-- Same shape as V1 and V3: ENABLE + FORCE, one FOR ALL policy carrying both USING and
-- WITH CHECK, NULLIF so an unset context yields no rows rather than an error.
-- ---------------------------------------------------------------------------------------
ALTER TABLE student_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_classes FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON student_classes
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE students FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON students
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE student_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_credentials FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON student_credentials
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardians FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON guardians
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE guardian_student_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardian_student_links FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON guardian_student_links
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE authorised_pickup_persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE authorised_pickup_persons FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON authorised_pickup_persons
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE custody_restrictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE custody_restrictions FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON custody_restrictions
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- Grants
--
-- No DELETE anywhere in this migration. Students are never hard-deleted while a safety
-- record references them (BR-STU-005); guardian links are deactivated, not removed, because
-- "who was authorised to collect this child in March" must stay answerable; and a revoked
-- pickup nomination is evidence. Withdrawal and revocation are UPDATEs to a status column.
-- ---------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON student_classes            TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON students                   TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON student_credentials        TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON guardians                  TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON guardian_student_links     TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON authorised_pickup_persons  TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON custody_restrictions       TO guardian_app;
