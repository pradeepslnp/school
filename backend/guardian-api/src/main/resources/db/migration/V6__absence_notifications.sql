-- V6 — Absence & Notification (MOD-14, MOD-12)
--
-- See docs/03-database/tables/MOD-13-14-incidents-absence.md, MOD-12-notification.md,
-- docs/04-api/TRIPS_BOARDING_API.md § Absence, and docs/01-product-discovery/NOTIFICATION_CATALOG.md.
--
-- Scope: what the parent app reads and writes — declared absences (P-06) and the durable
-- notification record (P-08). Templates, per-channel preferences, and delivery attempts
-- arrive with the dispatch engine (ADR-0005), which is what writes them.
--
-- Row-level security is applied HERE, in the same migration that creates the tables.

-- ---------------------------------------------------------------------------------------
-- absences (MOD-14)
--
-- A declared absence removes the child from the expected manifest at trip start
-- (BR-ABS-002), which is what stops reconciliation raising a false alarm about a child who
-- was never coming.
--
-- direction is NULLABLE and null means BOTH journeys. That matches the wire contract
-- (docs/04-api/TRIPS_BOARDING_API.md: `"direction": null`) rather than inventing a third
-- enum value the API would have to translate.
--
-- reason is nullable: requiring a parent to justify their child's absence is friction with
-- no safety value (BR-ABS-001).
-- ---------------------------------------------------------------------------------------
CREATE TABLE absences (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    student_id            UUID        NOT NULL REFERENCES students (id) ON DELETE RESTRICT,
    -- Who declared it. A guardian, so the record answers "who said this child was not
    -- travelling" without a join through users.
    declared_by_guardian_id UUID      NOT NULL REFERENCES guardians (id) ON DELETE RESTRICT,
    -- DATE, not TIMESTAMPTZ: an absence is a school-calendar fact, and an instant would put
    -- the boundary in the wrong day for any school not on UTC (BR-CFG-006).
    from_date             DATE        NOT NULL,
    to_date               DATE        NOT NULL,
    direction             VARCHAR(16),
    reason                TEXT,
    -- Cancellation is a status change, not a delete: a manifest was materialised from this
    -- declaration and the reason it excluded a child has to stay answerable (BR-ABS-004).
    status                VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
    cancelled_at          TIMESTAMPTZ,
    cancelled_by          UUID,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by            UUID,
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by            UUID,
    version               BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT ck_absences_range     CHECK (to_date >= from_date),
    CONSTRAINT ck_absences_direction CHECK (direction IS NULL OR direction IN ('PICKUP', 'DROP')),
    CONSTRAINT ck_absences_status    CHECK (status IN ('ACTIVE', 'CANCELLED'))
);

-- Manifest materialisation asks: "is this student absent on this date, this direction?"
CREATE INDEX idx_absences_student_range
    ON absences (tenant_id, student_id, from_date, to_date) WHERE status = 'ACTIVE';

-- ---------------------------------------------------------------------------------------
-- notifications (MOD-12) — the durable record behind P-08
--
-- "A parent who missed a push must be able to scroll back and find it"
-- (docs/05-ui/PARENT_APP.md). This table is that record; it is not the delivery mechanism.
--
-- catalog_id ties every row to an entry in NOTIFICATION_CATALOG.md, so "which message is
-- this" is answerable without parsing the text.
--
-- body_key + body_params rather than a rendered string: the server does not know the
-- guardian's language, so it stores the localisation key and its parameters and the client
-- renders (BR-CFG-005). A rendered string here would be frozen in whatever locale the
-- dispatcher happened to run in.
-- ---------------------------------------------------------------------------------------
CREATE TABLE notifications (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    -- The recipient, as a user rather than a guardian: staff receive notifications too, and
    -- one person may be both.
    user_id      UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    catalog_id   VARCHAR(32) NOT NULL,
    priority     VARCHAR(16) NOT NULL,
    body_key     VARCHAR(128) NOT NULL,
    body_params  JSONB       NOT NULL DEFAULT '{}'::jsonb,
    -- Fallback copy in the tenant's default locale, for a client that has no bundle for
    -- body_key yet. Never the authority for display.
    body_fallback TEXT       NOT NULL,
    -- Which child this concerns, so the entry can deep-link (never another family's child,
    -- BR-NTF-007 🔴).
    student_id   UUID        REFERENCES students (id) ON DELETE RESTRICT,
    trip_id      UUID        REFERENCES trips (id) ON DELETE RESTRICT,
    occurred_at  TIMESTAMPTZ NOT NULL,
    read_at      TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    version      BIGINT      NOT NULL DEFAULT 0,

    CONSTRAINT ck_notifications_priority CHECK (
        priority IN ('CRITICAL', 'URGENT', 'STANDARD', 'INFO'))
);

-- P-08's query: mine, newest first.
CREATE INDEX idx_notifications_user
    ON notifications (tenant_id, user_id, occurred_at DESC);
CREATE INDEX idx_notifications_unread
    ON notifications (tenant_id, user_id) WHERE read_at IS NULL;

-- ---------------------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------------------
ALTER TABLE absences ENABLE ROW LEVEL SECURITY;
ALTER TABLE absences FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON absences
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON notifications
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- Grants
--
-- No DELETE on either. An absence is cancelled, not erased — a manifest was built from it.
-- A notification is the evidence trail for "why was I not told?" (BR-NTF-005); deleting one
-- destroys exactly the record that question needs.
-- ---------------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON absences      TO guardian_app;
GRANT SELECT, INSERT, UPDATE ON notifications TO guardian_app;
