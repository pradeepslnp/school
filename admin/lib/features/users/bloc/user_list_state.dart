import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../../organizations/domain/onboarding_models.dart';
import '../domain/user_models.dart';

/// The Users screen (A-43), including the `SUPER_ADMIN` organization-picker step and the
/// create dialog's school-picker data.
///
/// One state class rather than a family of them, matching `StaffListState` — every field the
/// screen or its dialogs render is here.
class UserListState extends Equatable {
  const UserListState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.users = const [],
    this.error,
    this.errorMessageKey,
    this.needsOrganizationPicker = false,
    this.isLoadingOrganizations = false,
    this.organizations = const [],
    this.resolvedOrganizationId,
    this.schools = const [],
    this.actionNotice,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<AdminUser> users;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  /// True only for a `SUPER_ADMIN` who hasn't yet picked which organization to manage — see
  /// `UserListStarted`'s documentation for why `ORG_ADMIN`/`SCHOOL_ADMIN` never see this step.
  final bool needsOrganizationPicker;
  final bool isLoadingOrganizations;

  /// Every organization on the platform, for the picker shown when [needsOrganizationPicker]
  /// is true.
  final List<CreatedOrganization> organizations;

  /// The organization every list/create/update/toggle call targets, once known — either
  /// handed straight in (`ORG_ADMIN`), resolved from the caller's own school
  /// (`SCHOOL_ADMIN`), or picked from [organizations] (`SUPER_ADMIN`).
  final String? resolvedOrganizationId;

  /// The schools under [resolvedOrganizationId], for the create dialog's school dropdown
  /// (needed only when the role being granted is school-scoped — see
  /// `isSchoolScopedRole`). Loaded alongside the user list once the organization is known.
  final List<CreatedSchool> schools;

  /// A one-off confirmation to surface (e.g. "Invitation re-sent") after an operator action that
  /// returns no row — resend invitation / send reset link (ADR-0012). Shown once, then cleared.
  final String? actionNotice;

  UserListState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<AdminUser>? users,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
    bool? needsOrganizationPicker,
    bool? isLoadingOrganizations,
    List<CreatedOrganization>? organizations,
    String? resolvedOrganizationId,
    List<CreatedSchool>? schools,
    String? actionNotice,
    bool clearActionNotice = false,
  }) {
    return UserListState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      users: users ?? this.users,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
      needsOrganizationPicker: needsOrganizationPicker ?? this.needsOrganizationPicker,
      isLoadingOrganizations: isLoadingOrganizations ?? this.isLoadingOrganizations,
      organizations: organizations ?? this.organizations,
      resolvedOrganizationId: resolvedOrganizationId ?? this.resolvedOrganizationId,
      schools: schools ?? this.schools,
      actionNotice: clearActionNotice ? null : (actionNotice ?? this.actionNotice),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        users,
        error,
        errorMessageKey,
        needsOrganizationPicker,
        isLoadingOrganizations,
        organizations,
        resolvedOrganizationId,
        schools,
        actionNotice,
      ];
}
