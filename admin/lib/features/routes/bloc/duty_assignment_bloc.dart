import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/duty_assignment_models.dart';
import '../repository/duty_assignment_repository.dart';
import 'duty_assignment_event.dart';
import 'duty_assignment_state.dart';

/// Assigns and lists crew for one route (STF-004).
///
/// Depends on a repository only, never a data provider — matching `RouteListBloc`, so this is
/// tested with no HTTP and no fake server.
class DutyAssignmentBloc extends Bloc<DutyAssignmentEvent, DutyAssignmentState> {
  DutyAssignmentBloc({required DutyAssignmentRepository repository})
      : _repository = repository,
        super(const DutyAssignmentState()) {
    on<DutyAssignmentListRequested>(_onRequested);
    on<DutyAssigned>(_onAssigned);
    on<DutyReplaced>(_onReplaced);
    on<DutyRemoved>(_onRemoved);
  }

  final DutyAssignmentRepository _repository;

  Future<void> _onRequested(
      DutyAssignmentListRequested event, Emitter<DutyAssignmentState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listDutyAssignments(routeId: event.routeId);

    switch (result) {
      case Success<List<CreatedDutyAssignment>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, assignments: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onAssigned(DutyAssigned event, Emitter<DutyAssignmentState> emit) async {
    if (event.staffId.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.assignDuty(
      routeId: event.routeId,
      staffId: event.staffId,
      role: event.role,
      direction: event.direction,
    );

    switch (result) {
      case Success<CreatedDutyAssignment>():
        // Re-read rather than prepend what came back: the crew list carries each person's name,
        // and the write responses do not.
        await _reload(event.routeId, emit);
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onReplaced(DutyReplaced event, Emitter<DutyAssignmentState> emit) async {
    if (event.staffId.trim().isEmpty || event.reason.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.replaceDuty(
      assignmentId: event.assignmentId,
      staffId: event.staffId,
      reason: event.reason,
    );

    switch (result) {
      case Success<void>():
        await _reload(event.routeId, emit);
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onRemoved(DutyRemoved event, Emitter<DutyAssignmentState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.removeDuty(assignmentId: event.assignmentId);

    switch (result) {
      case Success<void>():
        await _reload(event.routeId, emit);
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  /// Re-reads the roster after a write. A failed re-read is not reported as a failed write — the
  /// change was saved; only the refresh was not.
  Future<void> _reload(String routeId, Emitter<DutyAssignmentState> emit) async {
    final refreshed = await _repository.listDutyAssignments(routeId: routeId);
    switch (refreshed) {
      case Success<List<CreatedDutyAssignment>>(:final value):
        emit(state.copyWith(isSubmitting: false, clearError: true, assignments: value));
      case Failure():
        emit(state.copyWith(isSubmitting: false, clearError: true));
    }
  }
}
