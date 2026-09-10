import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/custody_restriction_models.dart';
import '../repository/custody_restriction_repository.dart';
import 'student_custody_event.dart';
import 'student_custody_state.dart';

/// Records, lists, and lifts custody restrictions for one student (A-14, GRD-006).
///
/// Depends on a repository only. After a record or a lift it re-reads the list rather than
/// patching it locally — this is a safety-critical panel and it should show exactly what the
/// server holds, not an optimistic guess.
class StudentCustodyBloc extends Bloc<StudentCustodyEvent, StudentCustodyState> {
  StudentCustodyBloc({required CustodyRestrictionRepository repository})
      : _repository = repository,
        super(const StudentCustodyState()) {
    on<StudentCustodyRequested>(_onRequested);
    on<CustodyRestrictionRecorded>(_onRecorded);
    on<CustodyRestrictionLifted>(_onLifted);
  }

  final CustodyRestrictionRepository _repository;

  Future<void> _onRequested(
    StudentCustodyRequested event,
    Emitter<StudentCustodyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.list(studentId: event.studentId);
    switch (result) {
      case Success<List<CustodyRestriction>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, restrictions: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onRecorded(
    CustodyRestrictionRecorded event,
    Emitter<StudentCustodyState> emit,
  ) async {
    final hasGuardian = (event.restrictedGuardianId ?? '').isNotEmpty;
    final hasName = (event.restrictedPersonName ?? '').isNotEmpty;
    if (hasGuardian == hasName || event.reason.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _repository.record(
      studentId: event.studentId,
      restrictedGuardianId: event.restrictedGuardianId,
      restrictedPersonName: event.restrictedPersonName,
      restrictionType: event.restrictionType,
      reason: event.reason,
      effectiveUntil: event.effectiveUntil,
    );
    switch (result) {
      case Success<CustodyRestriction>():
        emit(state.copyWith(isSubmitting: false, clearError: true));
        add(StudentCustodyRequested(studentId: event.studentId));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onLifted(
    CustodyRestrictionLifted event,
    Emitter<StudentCustodyState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _repository.lift(
      studentId: event.studentId,
      restrictionId: event.restrictionId,
    );
    switch (result) {
      case Success<void>():
        emit(state.copyWith(isSubmitting: false, clearError: true));
        add(StudentCustodyRequested(studentId: event.studentId));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
