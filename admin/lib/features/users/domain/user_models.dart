import 'package:equatable/equatable.dart';

import '../../../l10n/generated/app_localizations.dart';

/// An administrative account (ORG_ADMIN, SCHOOL_ADMIN, PRINCIPAL, or TRANSPORT_MANAGER) as
/// returned by `GET /users`, `POST /users`, or a `PATCH /users/{id}` variant (IAM-005,
/// IAM-008), for the Users screen (A-43).
///
/// Deliberately excludes DRIVER/ATTENDANT (managed from the Drivers screen, A-23) and
/// GUARDIAN (never administered this way) — see `UserController` on the backend.
class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.preferredLocale,
    required this.status,
    required this.roleCodes,
    this.phone,
    this.scopeLevel,
    this.scopeRefId,
  });

  final String id;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;

  /// Drives the edit form's pre-filled value (`UpdateUserRequest.preferredLocale` is
  /// required on every save, even one that only changes the name) — see `UserResponse` on
  /// the backend for why this travels on every read.
  final String preferredLocale;

  /// `ACTIVE`, `INACTIVE`, or `PENDING` — see `UserStatus` on the backend. `PENDING` is an
  /// invited account that has not set a password yet (ADR-0012). Never `LOCKED` for an account
  /// this screen shows: a lock is a login-attempt outcome (BR-IAM-011), not an administrative
  /// state this screen sets.
  final String status;

  final List<String> roleCodes;

  /// `ORG` or `SCHOOL` — null only for a row this build cannot yet parse a scope for.
  final String? scopeLevel;

  /// The organization or school id the role applies to. Null for an `ORG`-scoped role, whose
  /// tenant already says which organization (see `UserScope` on the backend).
  final String? scopeRefId;

  String get displayName => '$firstName $lastName'.trim();

  bool get isActive => status == 'ACTIVE';

  /// Invited but not yet activated — has no password and cannot sign in (ADR-0012).
  bool get isPending => status == 'PENDING';

  /// The single role this screen expects a row to carry. Administrative accounts are created
  /// with exactly one role today (`CreateAdministrativeUserUseCase`); this is a display
  /// convenience, not a platform guarantee that a second could never appear.
  String get primaryRoleCode => roleCodes.isEmpty ? '' : roleCodes.first;

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        firstName,
        lastName,
        preferredLocale,
        status,
        roleCodes,
        scopeLevel,
        scopeRefId,
      ];
}

/// Display name for a role code, matching PERSONAS.md's own naming — the same five values
/// `roles/domain/permission_matrix.dart`'s own `roleDisplayName` resolves for its nine, so both
/// draw on the same `roleName*` ARB keys rather than risking the two drifting apart in Kannada
/// later.
String roleDisplayName(AppLocalizations l10n, String roleCode) => switch (roleCode) {
      'SUPER_ADMIN' => l10n.roleNameSuperAdmin,
      'ORG_ADMIN' => l10n.roleNameOrgAdmin,
      'SCHOOL_ADMIN' => l10n.roleNameSchoolAdmin,
      'PRINCIPAL' => l10n.roleNamePrincipal,
      'TRANSPORT_MANAGER' => l10n.roleNameTransportManager,
      _ => roleCode,
    };

/// Whether [roleCode] is scoped to one school rather than a whole organization — mirrors
/// `CreateAdministrativeUserUseCase.SCHOOL_SCOPED_ROLES` on the backend. Affordance only: the
/// server is what actually enforces this shape (BR-IAM-006).
bool isSchoolScopedRole(String roleCode) =>
    const {'SCHOOL_ADMIN', 'PRINCIPAL', 'TRANSPORT_MANAGER'}.contains(roleCode);

/// The administrative roles [actorRole] may create, in the order offered on the Create User
/// form — mirrors `CreateAdministrativeUserUseCase.ASSIGNABLE_ROLES` on the backend exactly.
///
/// **Affordance only** (BR-IAM-001, BR-IAM-006): hiding a role the server would refuse to
/// grant is a courtesy, matching every other client-side role check in this console
/// (`ConsoleDestinations.visibleTo`) — the server re-validates on every request regardless of
/// what this list offers.
List<String> assignableRoleCodes(List<String> actorRoles) {
  if (actorRoles.contains('SUPER_ADMIN')) {
    return const ['ORG_ADMIN', 'SCHOOL_ADMIN', 'PRINCIPAL', 'TRANSPORT_MANAGER'];
  }
  if (actorRoles.contains('ORG_ADMIN')) {
    return const ['SCHOOL_ADMIN', 'PRINCIPAL', 'TRANSPORT_MANAGER'];
  }
  if (actorRoles.contains('SCHOOL_ADMIN')) {
    return const ['PRINCIPAL', 'TRANSPORT_MANAGER'];
  }
  return const [];
}
