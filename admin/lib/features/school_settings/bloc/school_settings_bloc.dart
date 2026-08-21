import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../organizations/domain/onboarding_models.dart';
import '../../organizations/repository/organization_onboarding_repository.dart';
import 'school_settings_event.dart';
import 'school_settings_state.dart';

/// Loads and edits the signed-in operator's own school (A-41, TEN-002).
///
/// Depends on `OrganizationOnboardingRepository` rather than a repository of its own — that
/// repository already owns every school read/write the console makes (`getSchool`,
/// `updateSchool`), and this screen needs no organization-level call at all. A second
/// repository wrapping the same data provider would duplicate `_parseSchool` for no benefit;
/// see that repository's own documentation on `getSchool` for why a `SCHOOL_ADMIN` reaches a
/// school this way rather than through the Organizations list.
class SchoolSettingsBloc extends Bloc<SchoolSettingsEvent, SchoolSettingsState> {
  SchoolSettingsBloc({required OrganizationOnboardingRepository repository})
      : _repository = repository,
        super(const SchoolSettingsState()) {
    on<SchoolSettingsRequested>(_onRequested);
    on<SchoolSettingsSaved>(_onSaved);
  }

  final OrganizationOnboardingRepository _repository;

  Future<void> _onRequested(
    SchoolSettingsRequested event,
    Emitter<SchoolSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.getSchool(schoolId: event.schoolId);

    switch (result) {
      case Success<CreatedSchool>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, school: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onSaved(
    SchoolSettingsSaved event,
    Emitter<SchoolSettingsState> emit,
  ) async {
    if (event.name.trim().isEmpty || event.timezone.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.updateSchool(
      schoolId: event.schoolId,
      organizationId: event.organizationId,
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
}
