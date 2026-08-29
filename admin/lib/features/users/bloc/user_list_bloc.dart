import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../organizations/domain/onboarding_models.dart';
import '../../organizations/repository/organization_onboarding_repository.dart';
import '../domain/user_models.dart';
import '../repository/user_repository.dart';
import 'user_list_event.dart';
import 'user_list_state.dart';

/// Manages administrative accounts for one organization (A-43, IAM-005, IAM-008).
///
/// Depends on [OrganizationOnboardingRepository] as well as [UserRepository]: this screen is
/// the one place a `SUPER_ADMIN` needs to pick *which* organization to manage before it means
/// anything, and the one place a `SCHOOL_ADMIN` needs their own organization id resolved from
/// a school id — see [_onStarted]. Never a data provider directly, matching every other bloc
/// in this console, so this is tested with no HTTP.
class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc({
    required UserRepository userRepository,
    required OrganizationOnboardingRepository organizationRepository,
  })  : _userRepository = userRepository,
        _organizationRepository = organizationRepository,
        super(const UserListState()) {
    on<UserListStarted>(_onStarted);
    on<UserListOrganizationSelected>(_onOrganizationSelected);
    on<UserCreateRequested>(_onCreateRequested);
    on<UserProfileUpdateRequested>(_onProfileUpdateRequested);
    on<UserStatusToggleRequested>(_onStatusToggleRequested);
    on<UserInvitationResendRequested>(_onInvitationResendRequested);
    on<UserResetLinkRequested>(_onResetLinkRequested);
  }

  final UserRepository _userRepository;
  final OrganizationOnboardingRepository _organizationRepository;

  /// Three shapes, depending on what the signed-in operator already knows about themselves
  /// (`AuthenticatedUser.organizationScopeId`/`schoolScopeId`, read by the route that fires
  /// this event — this bloc never touches the session directly, matching `SchoolScopeBloc`):
  ///
  /// - `organizationId` set: an `ORG_ADMIN` — go straight to that organization's users.
  /// - `schoolIdToResolve` set: a `SCHOOL_ADMIN`, who holds no `PERM-ORG-VIEW` to look their
  ///   own organization up directly. One `GET /schools/{id}` call (already used by School
  ///   Settings, A-41) reads the school's `organizationId` — gated only by `PERM-SCHOOL-VIEW`,
  ///   which every `SCHOOL_ADMIN` holds.
  /// - Neither set: a `SUPER_ADMIN`, who oversees every organization and must pick one first.
  Future<void> _onStarted(UserListStarted event, Emitter<UserListState> emit) async {
    if (event.organizationId != null) {
      await _loadOrganization(event.organizationId!, emit);
      return;
    }

    if (event.schoolIdToResolve != null) {
      emit(state.copyWith(isLoading: true, clearError: true));

      final result =
          await _organizationRepository.getSchool(schoolId: event.schoolIdToResolve!);
      switch (result) {
        case Success<CreatedSchool>(:final value):
          await _loadOrganization(value.organizationId, emit);
        case Failure(:final code, :final messageKey):
          emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
      }
      return;
    }

    emit(state.copyWith(
      needsOrganizationPicker: true,
      isLoadingOrganizations: true,
      clearError: true,
    ));

    final result = await _organizationRepository.listOrganizations();
    switch (result) {
      case Success<List<CreatedOrganization>>(:final value):
        emit(state.copyWith(isLoadingOrganizations: false, organizations: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          isLoadingOrganizations: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }

  Future<void> _onOrganizationSelected(
      UserListOrganizationSelected event, Emitter<UserListState> emit) async {
    await _loadOrganization(event.organizationId, emit);
  }

  /// Loads the user list and school list for [organizationId] together — the school list
  /// backs the create dialog's school picker (only shown for a school-scoped role) and is
  /// cheap enough to fetch up front rather than only once the operator picks such a role.
  Future<void> _loadOrganization(String organizationId, Emitter<UserListState> emit) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      needsOrganizationPicker: false,
      resolvedOrganizationId: organizationId,
    ));

    // Both futures are created (and start running) before either is awaited, so the two
    // calls happen concurrently rather than one after the other — without depending on the
    // record-based `Future.wait` extension, whose availability isn't worth gambling on
    // without a local Dart SDK to check against.
    final usersFuture = _userRepository.listUsers(organizationId: organizationId);
    final schoolsFuture = _organizationRepository.listSchools(organizationId: organizationId);
    final usersResult = await usersFuture;
    final schoolsResult = await schoolsFuture;

    switch (usersResult) {
      case Success<List<AdminUser>>(:final value):
        final schools = switch (schoolsResult) {
          Success<List<CreatedSchool>>(value: final schoolList) => schoolList,
          // A school-list failure shouldn't block showing the user list itself — the create
          // dialog's school picker degrades to empty rather than the whole screen failing.
          Failure() => const <CreatedSchool>[],
        };
        emit(state.copyWith(isLoading: false, clearError: true, users: value, schools: schools));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onCreateRequested(
      UserCreateRequested event, Emitter<UserListState> emit) async {
    final organizationId = state.resolvedOrganizationId;
    if (organizationId == null) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    // The password is required only in PASSWORD mode; in INVITE mode the new user sets their own
    // (ADR-0012).
    final passwordMissing =
        !event.isInvite && (event.initialPassword == null || event.initialPassword!.trim().isEmpty);
    if (event.email.trim().isEmpty ||
        event.firstName.trim().isEmpty ||
        event.lastName.trim().isEmpty ||
        event.roleCode.trim().isEmpty ||
        passwordMissing) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    if (isSchoolScopedRole(event.roleCode) && (event.schoolId == null || event.schoolId!.isEmpty)) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _userRepository.createUser(
      organizationId: organizationId,
      schoolId: event.schoolId,
      email: event.email,
      phone: event.phone,
      firstName: event.firstName,
      lastName: event.lastName,
      roleCode: event.roleCode,
      initialPassword: event.initialPassword,
      deliveryMode: event.deliveryMode,
    );

    switch (result) {
      case Success<AdminUser>(:final value):
        // Prepended rather than re-fetched — matching StaffListBloc's reasoning: the operator
        // just created this row and should see it immediately.
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          users: [value, ...state.users],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onProfileUpdateRequested(
      UserProfileUpdateRequested event, Emitter<UserListState> emit) async {
    final organizationId = state.resolvedOrganizationId;
    if (organizationId == null ||
        event.firstName.trim().isEmpty ||
        event.lastName.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _userRepository.updateUser(
      userId: event.userId,
      organizationId: organizationId,
      firstName: event.firstName,
      lastName: event.lastName,
      preferredLocale: event.preferredLocale,
    );

    switch (result) {
      case Success<AdminUser>(:final value):
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          users: [
            for (final user in state.users)
              if (user.id == value.id) value else user,
          ],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onInvitationResendRequested(
      UserInvitationResendRequested event, Emitter<UserListState> emit) async {
    final organizationId = state.resolvedOrganizationId;
    if (organizationId == null) return;

    emit(state.copyWith(isSubmitting: true, clearError: true, clearActionNotice: true));

    final result =
        await _userRepository.resendInvitation(userId: event.userId, organizationId: organizationId);
    switch (result) {
      case Success<void>():
        emit(state.copyWith(isSubmitting: false, actionNotice: 'Invitation re-sent.'));
      case Failure<void>(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onResetLinkRequested(
      UserResetLinkRequested event, Emitter<UserListState> emit) async {
    final organizationId = state.resolvedOrganizationId;
    if (organizationId == null) return;

    emit(state.copyWith(isSubmitting: true, clearError: true, clearActionNotice: true));

    final result =
        await _userRepository.sendResetCode(userId: event.userId, organizationId: organizationId);
    switch (result) {
      case Success<void>():
        emit(state.copyWith(isSubmitting: false, actionNotice: 'Password-reset code emailed.'));
      case Failure<void>(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onStatusToggleRequested(
      UserStatusToggleRequested event, Emitter<UserListState> emit) async {
    final organizationId = state.resolvedOrganizationId;
    if (organizationId == null) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = event.activate
        ? await _userRepository.reactivateUser(userId: event.userId, organizationId: organizationId)
        : await _userRepository.deactivateUser(userId: event.userId, organizationId: organizationId);

    switch (result) {
      case Success<AdminUser>(:final value):
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          users: [
            for (final user in state.users)
              if (user.id == value.id) value else user,
          ],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
