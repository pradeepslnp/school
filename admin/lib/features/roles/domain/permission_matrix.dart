/// The system role → permission matrix, transcribed verbatim from
/// `PERMISSION_MATRIX.md` (the authoritative source — this file must be kept in sync with it
/// by hand, since `SystemRolePermissions.java` resolves this same data from code rather than
/// from a table this console could read directly; see that class's own Javadoc).
///
/// Backs the read-only Roles & permissions reference screen (A-44) — decision #3 in the
/// Super Admin build plan: a screen that lets someone *see* who can do what, not yet one that
/// lets them build a custom role.
///
/// Category titles, role names, and footnotes are resolved from [AppLocalizations] rather than
/// stored as literals (ADR-0013) — [permissionMatrix], [roleDisplayName], and [roleShortLabel]
/// all take it as a parameter and are called from `RoleReferenceScreen.build`, which already
/// holds a `BuildContext`.
library;

import '../../../l10n/generated/app_localizations.dart';

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
String roleDisplayName(AppLocalizations l10n, String roleCode) => switch (roleCode) {
      'SUPER_ADMIN' => l10n.roleNameSuperAdmin,
      'ORG_ADMIN' => l10n.roleNameOrgAdmin,
      'SCHOOL_ADMIN' => l10n.roleNameSchoolAdmin,
      'PRINCIPAL' => l10n.roleNamePrincipal,
      'TRANSPORT_MANAGER' => l10n.roleNameTransportManager,
      'VENDOR_STAFF' => l10n.roleNameVendorStaff,
      'DRIVER' => l10n.roleNameDriver,
      'ATTENDANT' => l10n.roleNameAttendant,
      'GUARDIAN' => l10n.roleNameGuardian,
      _ => roleCode,
    };

/// Short column headers for the matrix table — full names would force the table wider than
/// any screen this console targets.
String roleShortLabel(AppLocalizations l10n, String roleCode) => switch (roleCode) {
      'SUPER_ADMIN' => l10n.roleShortSuperAdmin,
      'ORG_ADMIN' => l10n.roleShortOrgAdmin,
      'SCHOOL_ADMIN' => l10n.roleShortSchoolAdmin,
      'PRINCIPAL' => l10n.roleShortPrincipal,
      'TRANSPORT_MANAGER' => l10n.roleShortTransportManager,
      'VENDOR_STAFF' => l10n.roleShortVendorStaff,
      'DRIVER' => l10n.roleShortDriver,
      'ATTENDANT' => l10n.roleShortAttendant,
      'GUARDIAN' => l10n.roleShortGuardian,
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

/// Builds the matrix for the active locale. A function rather than a top-level constant
/// (`kPermissionMatrix` before ADR-0013) because every title, and several footnotes, now come
/// from [AppLocalizations] rather than a literal — recomputed on each call, which is cheap
/// enough for a ~60-row reference table rendered by one screen.
List<PermissionCategory> permissionMatrix(AppLocalizations l10n) => [
      PermissionCategory(
        title: l10n.permCategoryTenancyConfig,
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
            note: l10n.permNoteConfigSafetyEdit,
          ),
        ],
      ),
      PermissionCategory(
        title: l10n.permCategoryIdentityAccess,
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
        title: l10n.permCategoryStudentsGuardians,
        permissions: [
          PermissionRow(id: 'PERM-STUDENT-CREATE', grants: _grants('FFF......')),
          PermissionRow(
            id: 'PERM-STUDENT-VIEW',
            grants: _grants('FFFFFNNNN'),
            note: l10n.permNoteStudentView,
          ),
          PermissionRow(id: 'PERM-STUDENT-EDIT', grants: _grants('FFF......')),
          PermissionRow(id: 'PERM-STUDENT-IMPORT', grants: _grants('FFF......')),
          PermissionRow(id: 'PERM-GUARDIAN-MANAGE', grants: _grants('FFF......')),
          PermissionRow(id: 'PERM-GUARDIAN-LINK', grants: _grants('FFF......')),
          PermissionRow(
            id: 'PERM-PICKUP-PERSON-MANAGE',
            grants: _grants('..F.....N'),
            note: l10n.permNotePickupPersonManage,
          ),
          PermissionRow(id: 'PERM-CUSTODY-RESTRICTION-MANAGE', grants: _grants('FFF......')),
          PermissionRow(
            id: 'PERM-HANDOVER-CODE-REQUEST',
            grants: _grants('........N'),
            note: l10n.permNoteHandoverCodeRequest,
          ),
        ],
      ),
      PermissionCategory(
        title: l10n.permCategoryFleetStaff,
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
        title: l10n.permCategoryRoutesTrips,
        permissions: [
          PermissionRow(id: 'PERM-ROUTE-MANAGE', grants: _grants('FFF.F....')),
          PermissionRow(id: 'PERM-ROUTE-VIEW', grants: _grants('FFFFFNNN.')),
          PermissionRow(id: 'PERM-ROUTE-ASSIGN-STUDENT', grants: _grants('FFF.F....')),
          PermissionRow(
            id: 'PERM-TRIP-VIEW',
            grants: _grants('FFFFFNNNN'),
            note: l10n.permNoteTripView,
          ),
          PermissionRow(id: 'PERM-TRIP-START', grants: _grants('....F.FF.')),
          PermissionRow(id: 'PERM-TRIP-END', grants: _grants('....F.FF.')),
          PermissionRow(id: 'PERM-TRIP-CANCEL', grants: _grants('FFF.F....')),
          PermissionRow(id: 'PERM-TRIP-CLOSE', grants: _grants('..F.F....')),
          PermissionRow(id: 'PERM-MANIFEST-AMEND', grants: _grants('..F.F..F.')),
        ],
      ),
      PermissionCategory(
        title: l10n.permCategoryBoardingHandover,
        permissions: [
          PermissionRow(id: 'PERM-BOARDING-RECORD', grants: _grants('....F.FF.')),
          PermissionRow(id: 'PERM-BOARDING-VIEW', grants: _grants('FFFFF.NNN')),
          PermissionRow(
            id: 'PERM-BOARDING-CORRECT',
            grants: _grants('..F.F..F.'),
            note: l10n.permNoteBoardingCorrect,
          ),
          PermissionRow(
            id: 'PERM-BOARDING-OVERRIDE',
            grants: _grants('..F.F..F.'),
            note: l10n.permNoteBoardingOverride,
          ),
          PermissionRow(id: 'PERM-HANDOVER-RECORD', grants: _grants('....F.FF.')),
          PermissionRow(
            id: 'PERM-HANDOVER-OVERRIDE',
            grants: _grants('..F.F..F.'),
            note: l10n.permNoteHandoverOverride,
          ),
          PermissionRow(
            id: 'PERM-RECONCILIATION-RESOLVE',
            grants: _grants('..F.F..F.'),
            note: l10n.permNoteReconciliationResolve,
          ),
        ],
      ),
      PermissionCategory(
        title: l10n.permCategoryTrackingAlertsIncidents,
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
            note: l10n.permNoteIncidentView,
          ),
          PermissionRow(id: 'PERM-INCIDENT-RESOLVE', grants: _grants('FFF.F....')),
        ],
      ),
      PermissionCategory(
        title: l10n.permCategoryAbsenceNotificationReportingAudit,
        permissions: [
          PermissionRow(
            id: 'PERM-ABSENCE-DECLARE',
            grants: _grants('..F.F...N'),
            note: l10n.permNoteAbsenceDeclare,
          ),
          PermissionRow(id: 'PERM-ABSENCE-VIEW', grants: _grants('FFFFF.NNN')),
          PermissionRow(id: 'PERM-NOTIFICATION-TEMPLATE-MANAGE', grants: _grants('FFF......')),
          PermissionRow(
            id: 'PERM-NOTIFICATION-SELF-VIEW',
            grants: _grants('FFFFFFFFF'),
            note: l10n.permNoteNotificationSelfView,
          ),
          PermissionRow(id: 'PERM-NOTIFICATION-PREFERENCE-SELF', grants: _grants('FFFFFFFFF')),
          PermissionRow(id: 'PERM-NOTIFICATION-DELIVERY-VIEW', grants: _grants('FFF.F....')),
          PermissionRow(id: 'PERM-REPORT-OPERATIONAL', grants: _grants('FFFFF....')),
          PermissionRow(id: 'PERM-REPORT-SAFETY', grants: _grants('FFFFF....')),
          PermissionRow(id: 'PERM-REPORT-COMPLIANCE', grants: _grants('FFFFF....')),
          PermissionRow(
            id: 'PERM-DATA-EXPORT',
            grants: _grants('FFF......'),
            note: l10n.permNoteDataExport,
          ),
          PermissionRow(id: 'PERM-AUDIT-VIEW', grants: _grants('FFFF.....')),
          PermissionRow(id: 'PERM-AUDIT-EXPORT', grants: _grants('FF.......')),
        ],
      ),
      PermissionCategory(
        title: l10n.permCategoryPlatformOperations,
        permissions: [
          PermissionRow(
            id: 'PERM-PLATFORM-TENANT-ACCESS',
            grants: _grants('F........'),
            note: l10n.permNotePlatformTenantAccess,
          ),
          PermissionRow(id: 'PERM-PLATFORM-HEALTH-VIEW', grants: _grants('F........')),
          PermissionRow(id: 'PERM-PLATFORM-REGION-MANAGE', grants: _grants('F........')),
        ],
      ),
    ];
