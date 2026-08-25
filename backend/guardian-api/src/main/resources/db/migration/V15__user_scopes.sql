-- V15 — User scopes (MOD-02)
--
-- See docs/03-database/tables/MOD-02-identity.md ("user_scopes") and PERMISSION_MATRIX.md
-- ("Permission alone is insufficient — every check resolves permission and scope", BR-IAM-006).
--
-- V3__identity.sql created users/roles/user_roles but, by its own header comment, only "what
-- session establishment needs" — permission resolution (V14) and this table were both left for
-- later. Until this migration, PERM-USER-CREATE had nowhere to record *which* organization or
-- school a newly created ORG_ADMIN/SCHOOL_ADMIN/PRINCIPAL/TRANSPORT_MANAGER actually administers,
-- and the admin console's session model (AuthenticatedUser.scopes) had no server-side source to
-- read from at all.
--
-- Same shape as the doc: PLATFORM and ORG scopes carry no ref id (a SUPER_ADMIN oversees every
-- organization; an ORG_ADMIN's own tenant_id already identifies which one — no second column
-- needed to say so again). SCHOOL and ROUTE scopes require one, because tenant_id alone does not
-- say *which* school or route within that tenant.
CREATE TABLE user_scopes (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    user_id       UUID        NOT NULL REFERENCES users (id)         ON DELETE CASCADE,
    scope_level   VARCHAR(24) NOT NULL,
    scope_ref_id  UUID,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_user_scopes_level CHECK (scope_level IN ('PLATFORM', 'ORG', 'SCHOOL', 'ROUTE')),
    CONSTRAINT ck_user_scopes_ref CHECK (
        (scope_level IN ('PLATFORM', 'ORG') AND scope_ref_id IS NULL)
     OR (scope_level IN ('SCHOOL', 'ROUTE') AND scope_ref_id IS NOT NULL))
);

CREATE INDEX idx_user_scopes_user ON user_scopes (tenant_id, user_id);

ALTER TABLE user_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_scopes FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON user_scopes
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- No DELETE: a scope is superseded by adding a new one for a role change, not removed out from
-- under an existing grant — matching this codebase's general preference for append-and-supersede
-- over in-place mutation of anything access-related (see user_roles' own comment on the same
-- table shape one migration up).
GRANT SELECT, INSERT ON user_scopes TO guardian_app;
