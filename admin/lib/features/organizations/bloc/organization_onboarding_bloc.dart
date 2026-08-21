import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/onboarding_models.dart';
import '../repository/organization_onboarding_repository.dart';
import 'organization_onboarding_event.dart';
import 'organization_onboarding_state.dart';

/// Onboards a new organization, then optionally its first school (TEN-001, TEN-002).
///
/// Depends on a repository only, never a data provider — matching `LoginBloc`, so this is
/// tested with no HTTP and no fake server.
class OrganizationOnboardingBloc
    extends Bloc<OrganizationOnboardingEvent, OrganizationOnboardingState> {
  OrganizationOnboardingBloc({required OrganizationOnboardingRepository repository})
      : _repository = repository,
        super(const OrganizationOnboardingState()) {
    on<OrganizationDetailsSubmitted>(_onOrganizationSubmitted);
    on<SchoolDetailsSubmitted>(_onSchoolSubmitted);
    on<OrganizationDetailsEdited>(_onOrganizationEdited);
    on<SchoolDetailsEdited>(_onSchoolEdited);
    on<OrganizationSelectedForViewing>(_onOrganizationSelectedForViewing);
    on<SchoolStepSkipped>(_onSchoolStepSkipped);
    on<OnboardingReset>(_onReset);
  }

  final OrganizationOnboardingRepository _repository;

  Future<void> _onOrganizationSubmitted(
    OrganizationDetailsSubmitted event,
    Emitter<OrganizationOnboardingState> emit,
  ) async {
    // The rest of what a well-formed code and name look like is the server's decision
    // (BR-TEN-007) — checked here only that something was entered, matching
    // `LoginBloc._onSubmitted`'s "not a second implementation of a rule that already exists"
    // reasoning.
    if (event.code.trim().isEmpty ||
        event.name.trim().isEmpty ||
        event.regionProfileCode.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.createOrganization(
      code: event.code,
      name: event.name,
      regionProfileCode: event.regionProfileCode,
      contactEmail: event.contactEmail,
      contactPhone: event.contactPhone,
    );

    switch (result) {
      case Success<CreatedOrganization>(:final value):
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          step: OnboardingStep.schoolDetails,
          organization: value,
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          isSubmitting: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }

  Future<void> _onSchoolSubmitted(
    SchoolDetailsSubmitted event,
    Emitter<OrganizationOnboardingState> emit,
  ) async {
    final organization = state.organization;
    if (organization == null) {
      // Reachable only if the widget dispatched this out of order — the screen only offers
      // this action once step 1 has set `organization`. Refused rather than guessed at,
      // matching the "refuse rather than pick a tenant at random" discipline used throughout
      // the backend for the same shape of mistake.
      emit(state.copyWith(error: ErrorCode.internalError));
      return;
    }

    if (event.code.trim().isEmpty || event.name.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.createSchool(
      organizationId: organization.id,
      code: event.code,
      name: event.name,
      timezone: event.timezone,
      latitude: event.latitude,
      longitude: event.longitude,
      geofenceRadiusM: event.geofenceRadiusM,
    );

    switch (result) {
      case Success<CreatedSchool>(:final value):
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          step: OnboardingStep.complete,
          school: value,
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          isSubmitting: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }

  Future<void> _onOrganizationEdited(
    OrganizationDetailsEdited event,
    Emitter<OrganizationOnboardingState> emit,
  ) async {
    final organization = state.organization;
    if (organization == null) {
      // The details view that dispatches this only exists once an organization has been
      // created — see `_onSchoolSubmitted`'s identical guard for the reasoning.
      emit(state.copyWith(error: ErrorCode.internalError));
      return;
    }

    if (event.name.trim().isEmpty || event.regionProfileCode.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.updateOrganization(
      organizationId: organization.id,
      name: event.name,
      regionProfileCode: event.regionProfileCode,
      contactEmail: event.contactEmail,
      contactPhone: event.contactPhone,
    );

    switch (result) {
      case Success<CreatedOrganization>(:final value):
        emit(state.copyWith(isSubmitting: false, clearError: true, organization: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onSchoolEdited(
    SchoolDetailsEdited event,
    Emitter<OrganizationOnboardingState> emit,
  ) async {
    final organization = state.organization;
    final school = state.school;
    if (organization == null || school == null) {
      emit(state.copyWith(error: ErrorCode.internalError));
      return;
    }

    if (event.name.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.updateSchool(
      schoolId: school.id,
      organizationId: organization.id,
      name: event.name,
      timezone: event.timezone,
      latitude: event.latitude,
      longitude: event.longitude,
      geofenceRadiusM: event.geofenceRadiusM,
    );

    switch (result) {
      case Success<CreatedSchool>(:final value):
        emit(state.copyWith(isSubmitting: false, clearError: true, school: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onOrganizationSelectedForViewing(
    OrganizationSelectedForViewing event,
    Emitter<OrganizationOnboardingState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSchool: true,
      step: OnboardingStep.complete,
      organization: event.organization,
    ));

    final result = await _repository.listSchools(organizationId: event.organization.id);

    switch (result) {
      case Success<List<CreatedSchool>>(:final value):
        // firstOrNull, not a lookup by "the" school: TEN-002 allows more than one, but this
        // console's onboarding flow only ever shows the first — see OrganizationDetailsView's
        // documentation on the same scope limit.
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          clearSchool: value.isEmpty,
          school: value.isEmpty ? null : value.first,
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  void _onSchoolStepSkipped(
    SchoolStepSkipped event,
    Emitter<OrganizationOnboardingState> emit,
  ) {
    emit(state.copyWith(step: OnboardingStep.complete, clearError: true));
  }

  void _onReset(
    OnboardingReset event,
    Emitter<OrganizationOnboardingState> emit,
  ) {
    emit(const OrganizationOnboardingState());
  }
}
