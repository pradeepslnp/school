import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/onboarding_models.dart';
import '../repository/organization_onboarding_repository.dart';
import 'organization_list_event.dart';
import 'organization_list_state.dart';

/// Lists every organization on the platform (A-41, TEN-001, `SUPER_ADMIN` only).
///
/// Depends on `OrganizationOnboardingRepository` rather than a repository of its own — that
/// repository already owns every organization/school data-provider call this console makes, and
/// splitting reads into a second repository over the same endpoints would be a second place to
/// keep the parsing in sync for no isolation this bloc actually needs (it never writes).
class OrganizationListBloc extends Bloc<OrganizationListEvent, OrganizationListState> {
  OrganizationListBloc({required OrganizationOnboardingRepository repository})
      : _repository = repository,
        super(const OrganizationListState()) {
    on<OrganizationListRequested>(_onRequested);
  }

  final OrganizationOnboardingRepository _repository;

  Future<void> _onRequested(
    OrganizationListRequested event,
    Emitter<OrganizationListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listOrganizations();

    switch (result) {
      case Success<List<CreatedOrganization>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, organizations: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }
}
