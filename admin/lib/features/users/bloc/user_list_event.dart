import 'package:equatable/equatable.dart';

/// What the operator did on the Users screen (A-43).
sealed class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown.
///
/// Exactly one of [organizationId] or [schoolIdToResolve] is set for a signed-in operator who
/// already knows their scope (`ORG_ADMIN`/`SCHOOL_ADMIN`); both are null for a `SUPER_ADMIN`,
/// who picks an organization first — see `UserListBloc._onStarted`.
final class UserListStarted extends UserListEvent {
  const UserListStarted({this.organizationId, this.schoolIdToResolve});

  final String? organizationId;

  /// A `SCHOOL_ADMIN`'s own school id (`AuthenticatedUser.schoolScopeId`) — resolved to its
  /// owning organization via one `GET /schools/{id}` call, because a `SCHOOL_ADMIN` holds no
  /// `PERM-ORG-VIEW` to look its organization up any other way.
  final String? schoolIdToResolve;

  @override
  List<Object?> get props => [organizationId, schoolIdToResolve];
}

/// A `SUPER_ADMIN` picked which organization's users to manage, from the picker shown when
/// [UserListStarted] resolved neither an organization nor a school.
final class UserListOrganizationSelected extends UserListEvent {
  const UserListOrganizationSelected(this.organizationId);

  final String organizationId;

  @override
  List<Object?> get props => [organizationId];
}

/// The operator created a new administrative account from the Create User dialog.
///
/// [deliveryMode] is `INVITE` (the default) or `PASSWORD` (ADR-0012). In invite mode
/// [initialPassword] is null — the new user sets their own via the emailed link.
final class UserCreateRequested extends UserListEvent {
  const UserCreateRequested({
    this.schoolId,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.roleCode,
    this.initialPassword,
    this.deliveryMode = 'INVITE',
  });

  final String? schoolId;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String roleCode;
  final String? initialPassword;
  final String deliveryMode;

  bool get isInvite => deliveryMode == 'INVITE';

  @override
  List<Object?> get props =>
      [schoolId, email, phone, firstName, lastName, roleCode, initialPassword, deliveryMode];
}

/// The operator re-sent an invitation to a still-pending account (ADR-0012).
final class UserInvitationResendRequested extends UserListEvent {
  const UserInvitationResendRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// The operator sent a password-reset link to an active account (ADR-0012).
final class UserResetLinkRequested extends UserListEvent {
  const UserResetLinkRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// The operator saved changes to an existing account's name/locale from the edit dialog.
final class UserProfileUpdateRequested extends UserListEvent {
  const UserProfileUpdateRequested({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.preferredLocale,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String preferredLocale;

  @override
  List<Object?> get props => [userId, firstName, lastName, preferredLocale];
}

/// The operator deactivated or reactivated an account.
final class UserStatusToggleRequested extends UserListEvent {
  const UserStatusToggleRequested({required this.userId, required this.activate});

  final String userId;
  final bool activate;

  @override
  List<Object?> get props => [userId, activate];
}
