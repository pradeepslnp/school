import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/staff_models.dart';
import '../repository/staff_repository.dart';
import 'staff_list_event.dart';
import 'staff_list_state.dart';

/// Registers and lists transport staff for one school (A-23, STF-001).
///
/// Depends on a repository only, never a data provider — matching `OrganizationListBloc`, so
/// this is tested with no HTTP and no fake server.
class StaffListBloc extends Bloc<StaffListEvent, StaffListState> {
  StaffListBloc({required StaffRepository repository})
      : _repository = repository,
        super(const StaffListState()) {
    on<StaffListRequested>(_onRequested);
    on<StaffCreated>(_onCreated);
    on<StaffUpdated>(_onUpdated);
    on<StaffDiscarded>(_onDiscarded);
  }

  final StaffRepository _repository;

  Future<void> _onRequested(StaffListRequested event, Emitter<StaffListState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listStaff(schoolId: event.schoolId);

    switch (result) {
      case Success<List<CreatedStaff>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, staff: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onCreated(StaffCreated event, Emitter<StaffListState> emit) async {
    if (event.firstName.trim().isEmpty ||
        event.lastName.trim().isEmpty ||
        event.phone.trim().isEmpty ||
        event.schoolId.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.createStaff(
      schoolId: event.schoolId,
      staffType: event.staffType,
      firstName: event.firstName,
      lastName: event.lastName,
      phone: event.phone,
      employeeCode: event.employeeCode,
      vendorName: event.vendorName,
    );

    switch (result) {
      case Success<CreatedStaff>(:final value):
        // Prepended rather than re-fetched: the operator just created this row and should see
        // it immediately, matching OrganizationListRoute's reasoning for why it refreshes on
        // return rather than trusting a stale list — the difference here is this bloc already
        // has the fact it needs without a second round trip.
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          staff: [value, ...state.staff],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onUpdated(StaffUpdated event, Emitter<StaffListState> emit) async {
    if (event.firstName.trim().isEmpty ||
        event.lastName.trim().isEmpty ||
        event.phone.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.updateStaff(
      staffId: event.staffId,
      firstName: event.firstName,
      lastName: event.lastName,
      phone: event.phone,
      employeeCode: event.employeeCode,
      vendorName: event.vendorName,
    );

    switch (result) {
      case Success<CreatedStaff>(:final value):
        // Replaces the edited row in place — matching `_onCreated`'s reasoning for updating
        // local state directly rather than re-fetching the whole roster for one change.
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          staff: [
            for (final staff in state.staff)
              if (staff.id == value.id) value else staff,
          ],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onDiscarded(StaffDiscarded event, Emitter<StaffListState> emit) async {
    if (event.reason.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.discardStaff(staffId: event.staffId, reason: event.reason);

    switch (result) {
      case Success<void>():
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          staff: [
            for (final staff in state.staff)
              if (staff.id != event.staffId) staff,
          ],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
