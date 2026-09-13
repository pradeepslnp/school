import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../organizations/domain/onboarding_models.dart';
import '../../../app/acting_organization.dart';
import '../../organizations/repository/organization_onboarding_repository.dart';
import 'school_scope_event.dart';
import 'school_scope_state.dart';

/// Resolves which school a school-scoped list screen (Students, Drivers, Vehicles, Routes)
/// should load, for an operator who holds no single-school scope
/// (`AuthenticatedUser.schoolScopeId` null) — an `ORG_ADMIN` or `SUPER_ADMIN`. A screen for a
/// role that does hold one never creates this bloc at all — see `StudentListRoute` and its
/// siblings.
///
/// Depends on `OrganizationOnboardingRepository` rather than a repository of its own, matching
/// `SchoolSettingsBloc`'s own reasoning: that repository already owns every organization/school
/// read this console makes, and this bloc writes nothing.
class SchoolScopeBloc extends Bloc<SchoolScopeEvent, SchoolScopeState> {
  SchoolScopeBloc({
    required OrganizationOnboardingRepository repository,
    ActingOrganization? actingOrganization,
  })  : _repository = repository,
        _actingOrganization = actingOrganization,
        super(const SchoolScopeState()) {
    on<SchoolScopeStarted>(_onStarted);
    on<SchoolScopeOrganizationSelected>(_onOrganizationSelected);
    on<SchoolScopeSchoolSelected>(_onSchoolSelected);
  }

  final OrganizationOnboardingRepository _repository;

  /// Set whenever the operator chooses an organization, so every later request in the console
  /// is made inside it (ADR-0016). Null for the screens and tests that do not wire one — the
  /// picker still works, the console simply stays in the session's own organization.
  final ActingOrganization? _actingOrganization;

  Future<void> _onStarted(SchoolScopeStarted event, Emitter<SchoolScopeState> emit) async {
    final organizationId = event.organizationScopeId;

    // An ORG_ADMIN's own organization is already known — go straight to its schools, no
    // organization picker shown at all.
    if (organizationId != null) {
      await _loadSchools(organizationId, emit, showOrganizationPicker: false);
      return;
    }

    // No organization scope — PLATFORM-level (SUPER_ADMIN) — the operator picks one first.
    emit(state.copyWith(
      showOrganizationPicker: true,
      isLoadingOrganizations: true,
      clearError: true,
    ));

    final result = await _repository.listOrganizations();
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
    SchoolScopeOrganizationSelected event,
    Emitter<SchoolScopeState> emit,
  ) async {
    // Before the fetch, not after: the schools list for another organization is itself a
    // cross-organization read, and must be made inside the organization being opened.
    _actingOrganization?.enter(event.organizationId);

    await _loadSchools(event.organizationId, emit, showOrganizationPicker: true);
  }

  void _onSchoolSelected(SchoolScopeSchoolSelected event, Emitter<SchoolScopeState> emit) {
    emit(state.copyWith(selectedSchoolId: event.schoolId));
  }

  Future<void> _loadSchools(
    String organizationId,
    Emitter<SchoolScopeState> emit, {
    required bool showOrganizationPicker,
  }) async {
    emit(state.copyWith(
      showOrganizationPicker: showOrganizationPicker,
      selectedOrganizationId: organizationId,
      isLoadingSchools: true,
      clearSelectedSchoolId: true,
      clearError: true,
    ));

    final result = await _repository.listSchools(organizationId: organizationId);
    switch (result) {
      case Success<List<CreatedSchool>>(:final value):
        emit(state.copyWith(
          isLoadingSchools: false,
          schools: value,
          // Most schools on this platform are the only school in their organization — nothing
          // to pick, so there is nothing for the operator to do here but wait.
          selectedSchoolId: value.length == 1 ? value.single.id : null,
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          isLoadingSchools: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }
}
