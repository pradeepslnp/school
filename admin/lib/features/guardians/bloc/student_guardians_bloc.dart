import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/guardian_models.dart';
import '../repository/guardian_repository.dart';
import 'student_guardians_event.dart';
import 'student_guardians_state.dart';

/// Lists and adds a student's guardians (A-11, GRD-001/GRD-002).
///
/// Depends on a repository only, never a data provider — matching `StaffListBloc`, so this is
/// tested with no HTTP and no fake server.
class StudentGuardiansBloc extends Bloc<StudentGuardiansEvent, StudentGuardiansState> {
  StudentGuardiansBloc({required GuardianRepository repository})
      : _repository = repository,
        super(const StudentGuardiansState()) {
    on<StudentGuardiansRequested>(_onRequested);
    on<GuardianAdded>(_onAdded);
  }

  final GuardianRepository _repository;

  Future<void> _onRequested(
      StudentGuardiansRequested event, Emitter<StudentGuardiansState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listGuardians(studentId: event.studentId);

    switch (result) {
      case Success<List<StudentGuardian>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, guardians: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onAdded(GuardianAdded event, Emitter<StudentGuardiansState> emit) async {
    if (event.firstName.trim().isEmpty ||
        event.lastName.trim().isEmpty ||
        event.phone.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.addGuardian(
      studentId: event.studentId,
      firstName: event.firstName,
      lastName: event.lastName,
      phone: event.phone,
      email: event.email,
      relationshipType: event.relationshipType,
      canView: event.canView,
      canReceiveNotifications: event.canReceiveNotifications,
      canAuthoriseHandover: event.canAuthoriseHandover,
      canDeclareAbsence: event.canDeclareAbsence,
      isPrimary: event.isPrimary,
    );

    switch (result) {
      case Success<StudentGuardian>(value: final created):
        // Re-list rather than prepend: adding an existing parent updates their link in place
        // (the backend upserts), so the returned row may already be in the list — a refresh
        // shows the authoritative set with its primary-first ordering intact, without this
        // panel having to reconcile an update-vs-insert itself.
        final refreshed = await _repository.listGuardians(studentId: event.studentId);
        switch (refreshed) {
          case Success<List<StudentGuardian>>(:final value):
            emit(state.copyWith(isSubmitting: false, clearError: true, guardians: value));
          case Failure():
            // The add succeeded; only the refresh failed. Fold the created row in rather than
            // reporting a failure for an operation that worked.
            emit(state.copyWith(
              isSubmitting: false,
              clearError: true,
              guardians: [created, ...state.guardians],
            ));
        }
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
