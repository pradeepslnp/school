-- V20 — Discarding mistaken entries and reading the staff register (ADR-0019)
--
-- See docs/00-governance/adr/ADR-0019-discarding-mistaken-entries-and-phone-correction.md,
-- docs/01-product-discovery/BUSINESS_RULES.md BR-STU-007 / BR-STAFF-007, and
-- docs/01-product-discovery/PERMISSION_MATRIX.md.
--
-- Permissions. System roles resolve them from SystemRolePermissions in code; these rows keep the
-- reference table the complete permission set custom roles are built from (V14).
INSERT INTO permissions (code, area, description_key) VALUES
    ('PERM-STUDENT-DELETE', 'STUDENT', 'permission.student_delete'),
    ('PERM-STAFF-VIEW',     'STAFF',   'permission.staff_view'),
    ('PERM-STAFF-DELETE',   'STAFF',   'permission.staff_delete');

-- ---------------------------------------------------------------------------------------
-- Grants
--
-- V4 withheld DELETE from every student table: a student with history is withdrawn, and a
-- guardian link is deactivated so "who was authorised to collect this child" stays answerable.
-- Both still hold. The one exception is a student entered by mistake (BR-STU-007): its own setup
-- rows — links, route assignments, credentials — are deleted with it, in one transaction.
--
-- What keeps this narrow is not these grants but the foreign keys: every table recording what
-- happened to a child (boarding_events, trip_manifests, absences, notifications,
-- handover_verification_codes, custody_restrictions, authorised_pickup_persons) references
-- students ON DELETE RESTRICT. A student with any such row cannot be deleted by any role, and the
-- discard's transaction rolls back its setup deletions with it.
--
-- No DELETE on users: sign-in accounts are released (role and sessions revoked, INACTIVE), never
-- deleted (BR-IAM-014). transport_staff, staff_credentials and duty_assignments already carry
-- DELETE (V9, V13).
-- ---------------------------------------------------------------------------------------
GRANT DELETE ON students                  TO guardian_app;
GRANT DELETE ON student_credentials       TO guardian_app;
GRANT DELETE ON guardian_student_links    TO guardian_app;
GRANT DELETE ON route_student_assignments TO guardian_app;

-- ---------------------------------------------------------------------------------------
-- Backfill transport_staff.user_id
--
-- Staff created through the API before this release were given a sign-in account, but the link
-- back to it was never persisted: the second save that sets user_id went through an update path
-- that did not copy the column. Phone correction and discard both act on that link (BR-IAM-014,
-- BR-STAFF-007), so it is restored here from the account provisioning actually created — the
-- same tenant, and the phone normalised the way PhoneNumber.of does (digits only, leading zeros
-- removed). Runs as the migration owner, which is not subject to row-level security, so the
-- tenant match is explicit.
-- ---------------------------------------------------------------------------------------
UPDATE transport_staff ts
SET user_id = u.id
FROM users u
WHERE ts.user_id IS NULL
  AND u.tenant_id = ts.tenant_id
  AND u.phone = ltrim(regexp_replace(ts.phone, '\D', '', 'g'), '0');
