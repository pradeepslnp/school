-- V14 — Permission resolution (MOD-02)
--
-- See docs/03-database/tables/MOD-02-identity.md and docs/01-product-discovery/PERMISSION_MATRIX.md.
--
-- V3 created roles and user_roles and said of them: "`permissions` and `role_permissions` arrive
-- with permission resolution; what exists here is what session establishment needs." This is that
-- arrival. Until now @RequiresPermission was read only at build time by an ArchUnit test — every
-- annotated endpoint was reachable by any authenticated caller regardless of role, which for this
-- platform meant a guardian's token could reach staff endpoints.
--
-- ## Why `permissions` carries no tenant_id and no RLS
--
-- It is platform reference data, like region_profiles (RLS_POLICIES.md, "Tables with no RLS").
-- Tenants assign permissions from this catalogue; they cannot invent them, so there is no
-- per-tenant variation to isolate. guardian_app therefore holds SELECT and nothing else: only a
-- migration ever writes this table.
--
-- Note the consequence for RlsSchemaInvariantsIT, which requires FORCE RLS on every table carrying
-- tenant_id. Adding a tenant_id here "for consistency" would oblige a policy on a table that must
-- be readable by every tenant, and the invariant would have to be weakened to permit it.
--
-- ## Why role_permissions references permissions.id rather than permissions.code
--
-- MOD-02-identity.md specifies role_id + permission_id. A code is a stable identifier for an API
-- contract and a poor one for a foreign key: renaming a permission would rewrite every grant row,
-- and PERMISSION_MATRIX.md is a living document.
--
-- ## Why the nine system roles have no rows in role_permissions
--
-- Their grants resolve from SystemRolePermissions in code. The matrix fixes them, so a row that
-- could be edited per tenant would contradict the document; and `roles` rows are created per
-- organization, so seeding template grants would require an organization-provisioning flow that
-- does not exist. role_permissions therefore serves tenant-defined roles only.

-- ---------------------------------------------------------------------------------------
-- permissions — the catalogue from PERMISSION_MATRIX.md
--
-- Seeded here rather than by the application: the matrix is the authority, and a catalogue the
-- application could write is one that can drift from it. An ArchUnit test already fails the build
-- for any @RequiresPermission naming a code the matrix does not list.
-- ---------------------------------------------------------------------------------------
CREATE TABLE permissions (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(64)  NOT NULL,
    -- The area segment of PERM-<AREA>-<ACTION>, for grouping in an administration UI.
    area            VARCHAR(64)  NOT NULL,
    -- Names a localisation resource; never user-facing text (BR-CFG-005), the same convention
    -- ErrorCode.messageKey() follows.
    description_key VARCHAR(128) NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uq_permissions_code UNIQUE (code)
);

INSERT INTO permissions (code, area, description_key) VALUES
    -- Tenancy & configuration
    ('PERM-ORG-CREATE',                    'ORG',                 'permission.org_create'),
    ('PERM-ORG-VIEW',                      'ORG',                 'permission.org_view'),
    ('PERM-ORG-EDIT',                      'ORG',                 'permission.org_edit'),
    ('PERM-ORG-SUSPEND',                   'ORG',                 'permission.org_suspend'),
    ('PERM-SCHOOL-CREATE',                 'SCHOOL',              'permission.school_create'),
    ('PERM-SCHOOL-VIEW',                   'SCHOOL',              'permission.school_view'),
    ('PERM-SCHOOL-EDIT',                   'SCHOOL',              'permission.school_edit'),
    ('PERM-CONFIG-VIEW',                   'CONFIG',              'permission.config_view'),
    ('PERM-CONFIG-EDIT',                   'CONFIG',              'permission.config_edit'),
    ('PERM-CONFIG-SAFETY-EDIT',            'CONFIG',              'permission.config_safety_edit'),
    -- Identity & access
    ('PERM-USER-CREATE',                   'USER',                'permission.user_create'),
    ('PERM-USER-VIEW',                     'USER',                'permission.user_view'),
    ('PERM-USER-EDIT',                     'USER',                'permission.user_edit'),
    ('PERM-USER-DEACTIVATE',               'USER',                'permission.user_deactivate'),
    ('PERM-ROLE-MANAGE',                   'ROLE',                'permission.role_manage'),
    ('PERM-SESSION-REVOKE',                'SESSION',             'permission.session_revoke'),
    ('PERM-PROFILE-SELF-EDIT',             'PROFILE',             'permission.profile_self_edit'),
    -- Students & guardians
    ('PERM-STUDENT-CREATE',                'STUDENT',             'permission.student_create'),
    ('PERM-STUDENT-VIEW',                  'STUDENT',             'permission.student_view'),
    ('PERM-STUDENT-EDIT',                  'STUDENT',             'permission.student_edit'),
    ('PERM-STUDENT-IMPORT',                'STUDENT',             'permission.student_import'),
    ('PERM-GUARDIAN-MANAGE',               'GUARDIAN',            'permission.guardian_manage'),
    ('PERM-GUARDIAN-LINK',                 'GUARDIAN',            'permission.guardian_link'),
    ('PERM-PICKUP-PERSON-MANAGE',          'PICKUP-PERSON',       'permission.pickup_person_manage'),
    ('PERM-HANDOVER-CODE-REQUEST',         'HANDOVER',            'permission.handover_code_request'),
    ('PERM-CUSTODY-RESTRICTION-MANAGE',    'CUSTODY-RESTRICTION', 'permission.custody_restriction_manage'),
    -- Fleet & staff
    ('PERM-VEHICLE-MANAGE',                'VEHICLE',             'permission.vehicle_manage'),
    ('PERM-VEHICLE-VIEW',                  'VEHICLE',             'permission.vehicle_view'),
    ('PERM-VEHICLE-DOCUMENT-MANAGE',       'VEHICLE-DOCUMENT',    'permission.vehicle_document_manage'),
    ('PERM-DEVICE-MANAGE',                 'DEVICE',              'permission.device_manage'),
    ('PERM-STAFF-MANAGE',                  'STAFF',               'permission.staff_manage'),
    ('PERM-STAFF-VERIFY',                  'STAFF',               'permission.staff_verify'),
    ('PERM-DUTY-ASSIGN',                   'DUTY',                'permission.duty_assign'),
    -- Routes & trips
    ('PERM-ROUTE-MANAGE',                  'ROUTE',               'permission.route_manage'),
    ('PERM-ROUTE-VIEW',                    'ROUTE',               'permission.route_view'),
    ('PERM-ROUTE-ASSIGN-STUDENT',          'ROUTE',               'permission.route_assign_student'),
    ('PERM-TRIP-VIEW',                     'TRIP',                'permission.trip_view'),
    ('PERM-TRIP-START',                    'TRIP',                'permission.trip_start'),
    ('PERM-TRIP-END',                      'TRIP',                'permission.trip_end'),
    ('PERM-TRIP-CANCEL',                   'TRIP',                'permission.trip_cancel'),
    ('PERM-TRIP-CLOSE',                    'TRIP',                'permission.trip_close'),
    ('PERM-MANIFEST-AMEND',                'MANIFEST',            'permission.manifest_amend'),
    -- Boarding & handover
    ('PERM-BOARDING-RECORD',               'BOARDING',            'permission.boarding_record'),
    ('PERM-BOARDING-VIEW',                 'BOARDING',            'permission.boarding_view'),
    ('PERM-BOARDING-CORRECT',              'BOARDING',            'permission.boarding_correct'),
    ('PERM-BOARDING-OVERRIDE',             'BOARDING',            'permission.boarding_override'),
    ('PERM-HANDOVER-RECORD',               'HANDOVER',            'permission.handover_record'),
    ('PERM-HANDOVER-OVERRIDE',             'HANDOVER',            'permission.handover_override'),
    ('PERM-RECONCILIATION-RESOLVE',        'RECONCILIATION',      'permission.reconciliation_resolve'),
    -- Tracking, alerts, incidents
    ('PERM-TRACKING-LIVE-VIEW',            'TRACKING',            'permission.tracking_live_view'),
    ('PERM-TRACKING-HISTORY-VIEW',         'TRACKING',            'permission.tracking_history_view'),
    ('PERM-ALERT-VIEW',                    'ALERT',               'permission.alert_view'),
    ('PERM-ALERT-RESOLVE',                 'ALERT',               'permission.alert_resolve'),
    ('PERM-SOS-RAISE',                     'SOS',                 'permission.sos_raise'),
    ('PERM-SOS-ACKNOWLEDGE',               'SOS',                 'permission.sos_acknowledge'),
    ('PERM-INCIDENT-CREATE',               'INCIDENT',            'permission.incident_create'),
    ('PERM-INCIDENT-VIEW',                 'INCIDENT',            'permission.incident_view'),
    ('PERM-INCIDENT-RESOLVE',              'INCIDENT',            'permission.incident_resolve'),
    -- Absence, notification, reporting, audit
    ('PERM-ABSENCE-DECLARE',               'ABSENCE',             'permission.absence_declare'),
    ('PERM-ABSENCE-VIEW',                  'ABSENCE',             'permission.absence_view'),
    ('PERM-NOTIFICATION-TEMPLATE-MANAGE',  'NOTIFICATION',        'permission.notification_template_manage'),
    ('PERM-NOTIFICATION-PREFERENCE-SELF',  'NOTIFICATION',        'permission.notification_preference_self'),
    ('PERM-NOTIFICATION-SELF-VIEW',        'NOTIFICATION',        'permission.notification_self_view'),
    ('PERM-NOTIFICATION-DELIVERY-VIEW',    'NOTIFICATION',        'permission.notification_delivery_view'),
    ('PERM-REPORT-OPERATIONAL',            'REPORT',              'permission.report_operational'),
    ('PERM-REPORT-SAFETY',                 'REPORT',              'permission.report_safety'),
    ('PERM-REPORT-COMPLIANCE',             'REPORT',              'permission.report_compliance'),
    ('PERM-DATA-EXPORT',                   'DATA',                'permission.data_export'),
    ('PERM-AUDIT-VIEW',                    'AUDIT',               'permission.audit_view'),
    ('PERM-AUDIT-EXPORT',                  'AUDIT',               'permission.audit_export'),
    -- Platform operations
    ('PERM-PLATFORM-TENANT-ACCESS',        'PLATFORM',            'permission.platform_tenant_access'),
    ('PERM-PLATFORM-HEALTH-VIEW',          'PLATFORM',            'permission.platform_health_view'),
    ('PERM-PLATFORM-REGION-MANAGE',        'PLATFORM',            'permission.platform_region_manage');

-- ---------------------------------------------------------------------------------------
-- role_permissions — grants for tenant-defined roles only
--
-- Same minimal shape as user_roles (V3) rather than the full standard-column block: a grant is
-- held or it is not, never edited in place, so updated_at and version have nothing to describe.
-- ---------------------------------------------------------------------------------------
CREATE TABLE role_permissions (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID        NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
    role_id       UUID        NOT NULL REFERENCES roles (id)         ON DELETE RESTRICT,
    permission_id UUID        NOT NULL REFERENCES permissions (id)   ON DELETE RESTRICT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_role_permissions UNIQUE (tenant_id, role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role ON role_permissions (tenant_id, role_id);

-- ---------------------------------------------------------------------------------------
-- Row-level security
--
-- role_permissions only. See the header for why permissions has none.
-- ---------------------------------------------------------------------------------------
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON role_permissions
    FOR ALL
    USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);

-- ---------------------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------------------
GRANT SELECT                         ON permissions      TO guardian_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON role_permissions TO guardian_app;
