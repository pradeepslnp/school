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
      case Success<CreatedDutyAssignment>(:final value):
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          assignments: [value, ...state.assignments],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
