/// The system role → permission matrix, transcribed verbatim from
/// `PERMISSION_MATRIX.md` (the authoritative source — this file must be kept in sync with it
/// by hand, since `SystemRolePermissions.java` resolves this same data from code rather than
/// from a table this console could read directly; see that class's own Javadoc).
///
/// Backs the read-only Roles & permissions reference screen (A-44) — decision #3 in the
/// Super Admin build plan: a screen that lets someone *see* who can do what, not yet one that
/// lets them build a custom role.
library;

/// The nine system roles, in `PERMISSION_MATRIX.md`'s own column order.
const List<String> kSystemRoleCodes = [
  'SUPER_ADMIN',
  'ORG_ADMIN',
  'SCHOOL_ADMIN',
  'PRINCIPAL',
  'TRANSPORT_MANAGER',
  'VENDOR_STAFF',
  'DRIVER',
  'ATTENDANT',
  'GUARDIAN',
];

/// Full display name for a role code, matching PERSONAS.md's own naming.
///
/// Deliberately not imported from `features/users/domain/user_models.dart`, whose own
/// `roleDisplayName` covers only the five admin-console roles that screen ever shows —
/// duplicated and extended to all nine here rather than reached across a feature boundary
/// for it, matching PROJECT_STRUCTURE.md §Flutter Layout's discipline that each feature
/// under `features/` stays self-contained.
String roleDisplayName(String roleCode) => switch (roleCode) {
      'SUPER_ADMIN' => 'Super Admin',
      'ORG_ADMIN' => 'Organization Admin',
      'SCHOOL_ADMIN' => 'School Admin',
      'PRINCIPAL' => 'Principal',
      'TRANSPORT_MANAGER' => 'Transport Manager',
      'VENDOR_STAFF' => 'Vendor Staff',
      'DRIVER' => 'Driver',
      'ATTENDANT' => 'Attendant',
      'GUARDIAN' => 'Guardian',
      _ => roleCode,
    };

/// Short column headers for the matrix table — full names would force the table wider than
/// any screen this console targets.
String roleShortLabel(String roleCode) => switch (roleCode) {
      'SUPER_ADMIN' => 'Super\nAdmin',
      'ORG_ADMIN' => 'Org\nAdmin',
      'SCHOOL_ADMIN' => 'School\nAdmin',
      'PRINCIPAL' => 'Principal',
      'TRANSPORT_MANAGER' => 'Transport\nMgr',
      'VENDOR_STAFF' => 'Vendor\nStaff',
      'DRIVER' => 'Driver',
      'ATTENDANT' => 'Attendant',
      'GUARDIAN' => 'Guardian',
      _ => roleCode,
    };

/// One cell of the matrix: `✔` (full, at the role's default scope), `✔*` (granted but
/// narrowed to something smaller than the role's default scope — e.g. a guardian seeing only
/// their own children), or denied.
enum PermissionGrant { none, full, narrower }

class PermissionRow {
  const PermissionRow({required this.id, required this.grants, this.note});

  final String id;
  final Map<String, PermissionGrant> grants;

  /// The matrix's own footnote for this permission, if any — shown under the row rather than
  /// crammed into a cell.
  final String? note;
}

class PermissionCategory {
  const PermissionCategory({required this.title, required this.permissions});

  final String title;
  final List<PermissionRow> permissions;
}

/// Decodes a 9-character shorthand in [kSystemRoleCodes] order: `F` full, `N` narrower, `.`
/// denied — matching the matrix's `✔` / `✔*` / blank.
Map<String, PermissionGrant> _grants(String pattern) {
  assert(pattern.length == kSystemRoleCodes.length);
  final map = <String, PermissionGrant>{};
  for (var i = 0; i < kSystemRoleCodes.length; i++) {
    map[kSystemRoleCodes[i]] = switch (pattern[i]) {
      'F' => PermissionGrant.full,
      'N' => PermissionGrant.narrower,
      _ => PermissionGrant.none,
    };
  }
  return map;
}

// `final`, not `const`: `_grants` builds each row's map with a runtime loop, which a
// compile-time constant expression cannot invoke. The list and its `PermissionCategory`/
// `PermissionRow` elements are still created exactly once, at first access, same as a
// `const` would be — this differs only in when the compiler is allowed to do the work.
final List<PermissionCategory> kPermissionMatrix = [
  PermissionCategory(
    title: 'Tenancy & Configuration',
    permissions: [
      PermissionRow(id: 'PERM-ORG-CREATE', grants: _grants('F........')),
      PermissionRow(id: 'PERM-ORG-VIEW', grants: _grants('FF.......')),
      PermissionRow(id: 'PERM-ORG-EDIT', grants: _grants('FF.......')),
      PermissionRow(id: 'PERM-ORG-SUSPEND', grants: _grants('F........')),
      PermissionRow(id: 'PERM-SCHOOL-CREATE', grants: _grants('FF.......')),
      PermissionRow(id: 'PERM-SCHOOL-VIEW', grants: _grants('FFFFF....')),
      PermissionRow(id: 'PERM-SCHOOL-EDIT', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-CONFIG-VIEW', grants: _grants('FFFF.....')),
      PermissionRow(id: 'PERM-CONFIG-EDIT', grants: _grants('FFN......')),
      PermissionRow(
        id: 'PERM-CONFIG-SAFETY-EDIT',
        grants: _grants('FF.......'),
        note: 'Governs safety-relevant thresholds; bounded by platform floors (BR-CFG-003).',
      ),
    ],
  ),
  PermissionCategory(
    title: 'Identity & Access',
    permissions: [
      PermissionRow(id: 'PERM-USER-CREATE', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-USER-VIEW', grants: _grants('FFFFN....')),
      PermissionRow(id: 'PERM-USER-EDIT', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-USER-DEACTIVATE', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-ROLE-MANAGE', grants: _grants('FF.......')),
      PermissionRow(id: 'PERM-SESSION-REVOKE', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-PROFILE-SELF-EDIT', grants: _grants('FFFFFFFFF')),
    ],
  ),
  PermissionCategory(
    title: 'Students & Guardians',
    permissions: [
      PermissionRow(id: 'PERM-STUDENT-CREATE', grants: _grants('FFF......')),
      PermissionRow(
        id: 'PERM-STUDENT-VIEW',
        grants: _grants('FFFFFNNNN'),
        note: 'Non-admin roles see only the current trip manifest or their own children '
            '(BR-IAM-005); non-guardian access is logged (BR-IAM-012).',
      ),
      PermissionRow(id: 'PERM-STUDENT-EDIT', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-STUDENT-IMPORT', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-GUARDIAN-MANAGE', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-GUARDIAN-LINK', grants: _grants('FFF......')),
      PermissionRow(
        id: 'PERM-PICKUP-PERSON-MANAGE',
        grants: _grants('..F.....N'),
        note: "A guardian's grant requires the \"authorise handover\" right on the "
            'relationship (BR-GRD-006).',
      ),
      PermissionRow(id: 'PERM-CUSTODY-RESTRICTION-MANAGE', grants: _grants('FFF......')),
      PermissionRow(
        id: 'PERM-HANDOVER-CODE-REQUEST',
        grants: _grants('........N'),
        note: 'Requires "can_authorise_handover" on the relationship (BR-GRD-006); '
            'redemption at the vehicle is the separate attendant-side flow (BR-HAND-001–007).',
      ),
    ],
  ),
  PermissionCategory(
    title: 'Fleet & Staff',
    permissions: [
      PermissionRow(id: 'PERM-VEHICLE-MANAGE', grants: _grants('FFF.F....')),
      PermissionRow(id: 'PERM-VEHICLE-VIEW', grants: _grants('FFFFFN...')),
      PermissionRow(id: 'PERM-VEHICLE-DOCUMENT-MANAGE', grants: _grants('FFF.F....')),
      PermissionRow(id: 'PERM-DEVICE-MANAGE', grants: _grants('FF..F....')),
      PermissionRow(id: 'PERM-STAFF-MANAGE', grants: _grants('FFF.F....')),
      PermissionRow(id: 'PERM-STAFF-VERIFY', grants: _grants('FFF......')),
      PermissionRow(id: 'PERM-DUTY-ASSIGN', grants: _grants('FF..F....')),
    ],
  ),
  PermissionCategory(
    title: 'Routes & Trips',
    permissions: [
      PermissionRow(id: 'PERM-ROUTE-MANAGE', grants: _grants('FFF.F....')),
      PermissionRow(id: 'PERM-ROUTE-VIEW', grants: _grants('FFFFFNNN.')),
      PermissionRow(id: 'PERM-ROUTE-ASSIGN-STUDENT', grants: _grants('FFF.F....')),
      PermissionRow(
        id: 'PERM-TRIP-VIEW',
        grants: _grants('FFFFFNNNN'),
        note: "A guardian's grant is limited to trips carrying one of their children "
            '(BR-TRACK-002).',
      ),
      PermissionRow(id: 'PERM-TRIP-START', grants: _grants('....F.FF.')),
      PermissionRow(id: 'PERM-TRIP-END', grants: _grants('....F.FF.')),
      PermissionRow(id: 'PERM-TRIP-CANCEL', grants: _grants('FFF.F....')),
      PermissionRow(id: 'PERM-TRIP-CLOSE', grants: _grants('..F.F....')),
      PermissionRow(id: 'PERM-MANIFEST-AMEND', grants: _grants('..F.F..F.')),
    ],
  ),
  PermissionCategory(
    title: 'Boarding & Handover',
    permissions: [
      PermissionRow(id: 'PERM-BOARDING-RECORD', grants: _grants('....F.FF.')),
      PermissionRow(id: 'PERM-BOARDING-VIEW', grants: _grants('FFFFF.NNN')),
      PermissionRow(
        id: 'PERM-BOARDING-CORRECT',
        grants: _grants('..F.F..F.'),
        note: 'Override-capable; always audited with a reason (BR-AUD-004).',
      ),
      PermissionRow(
        id: 'PERM-BOARDING-OVERRIDE',
        grants: _grants('..F.F..F.'),
        note: 'Override-capable; always audited with a reason (BR-AUD-004).',
      ),
      PermissionRow(id: 'PERM-HANDOVER-RECORD', grants: _grants('....F.FF.')),
      PermissionRow(
        id: 'PERM-HANDOVER-OVERRIDE',
        grants: _grants('..F.F..F.'),
        note: 'Notifies all guardians and the transport manager (BR-HAND-003); always '
            'audited with a reason (BR-AUD-004).',
      ),
      PermissionRow(
        id: 'PERM-RECONCILIATION-RESOLVE',
        grants: _grants('..F.F..F.'),
        note: 'Override-capable; always audited with a reason (BR-AUD-004).',
      ),
    ],
  ),
  PermissionCategory(
    title: 'Tracking, Alerts, Incidents',
    permissions: [
      PermissionRow(id: 'PERM-TRACKING-LIVE-VIEW', grants: _grants('FFFFFN..N')),
      PermissionRow(id: 'PERM-TRACKING-HISTORY-VIEW', grants: _grants('FFFFF....')),
      PermissionRow(id: 'PERM-ALERT-VIEW', grants: _grants('FFFFFN...')),
      PermissionRow(id: 'PERM-ALERT-RESOLVE', grants: _grants('FFF.F....')),
      PermissionRow(id: 'PERM-SOS-RAISE', grants: _grants('....F.FF.')),
      PermissionRow(id: 'PERM-SOS-ACKNOWLEDGE', grants: _grants('FFFFF....')),
      PermissionRow(id: 'PERM-INCIDENT-CREATE', grants: _grants('..F.FFFF.')),
      PermissionRow(
        id: 'PERM-INCIDENT-VIEW',
        grants: _grants('FFFFFN..N'),
        note: "A guardian's grant is limited to incidents affecting their own child "
            '(BR-INC-004, BR-NTF-007).',
      ),
      PermissionRow(id: 'PERM-INCIDENT-RESOLVE', grants: _grants('FFF.F....')),
    ],
  ),
  PermissionCategory(
    title: 'Absence, Notification, Reporting, Audit',
    permissions: [
      PermissionRow(
        id: 'PERM-ABSENCE-DECLARE',
        grants: _grants('..F.F...N'),
        note: "A guardian's grant requires the \"declare absence\" right (BR-ABS-001).",
      ),
      PermissionRow(id: 'PERM-ABSENCE-VIEW', grants: _grants('FFFFF.NNN')),
      PermissionRow(id: 'PERM-NOTIFICATION-TEMPLATE-MANAGE', grants: _grants('FFF......')),
      PermissionRow(
        id: 'PERM-NOTIFICATION-SELF-VIEW',
        grants: _grants('FFFFFFFFF'),
        note: 'Everyone, scoped to their own notifications only — never a route to another '
            "family's child (BR-NTF-007).",
      ),
      PermissionRow(id: 'PERM-NOTIFICATION-PREFERENCE-SELF', grants: _grants('FFFFFFFFF')),
      PermissionRow(id: 'PERM-NOTIFICATION-DELIVERY-VIEW', grants: _grants('FFF.F....')),
      PermissionRow(id: 'PERM-REPORT-OPERATIONAL', grants: _grants('FFFFF....')),
      PermissionRow(id: 'PERM-REPORT-SAFETY', grants: _grants('FFFFF....')),
      PermissionRow(id: 'PERM-REPORT-COMPLIANCE', grants: _grants('FFFFF....')),
      PermissionRow(
        id: 'PERM-DATA-EXPORT',
        grants: _grants('FFF......'),
        note: 'Always audited with actor, scope, and record count (BR-RPT-002).',
      ),
      PermissionRow(id: 'PERM-AUDIT-VIEW', grants: _grants('FFFF.....')),
      PermissionRow(id: 'PERM-AUDIT-EXPORT', grants: _grants('FF.......')),
    ],
  ),
  PermissionCategory(
    title: 'Platform Operations',
    permissions: [
      PermissionRow(
        id: 'PERM-PLATFORM-TENANT-ACCESS',
        grants: _grants('F........'),
        note: 'The only path across the tenant boundary (BR-TEN-004); every use is audited '
            'with the target organization and justification (AUD-004).',
      ),
      PermissionRow(id: 'PERM-PLATFORM-HEALTH-VIEW', grants: _grants('F........')),
      PermissionRow(id: 'PERM-PLATFORM-REGION-MANAGE', grants: _grants('F........')),
    ],
  ),
];
