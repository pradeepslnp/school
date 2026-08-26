import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/route_assignment_models.dart';
import '../repository/route_assignment_repository.dart';
import 'student_assignments_event.dart';
import 'student_assignments_state.dart';

/// Lists, adds, and removes a student's pickup/drop assignments (RTE-003, A-11).
///
/// Depends on a repository only, never a data provider — matching `StaffListBloc`, so this is
/// tested with no HTTP and no fake server.
class StudentAssignmentsBloc
    extends Bloc<StudentAssignmentsEvent, StudentAssignmentsState> {
  StudentAssignmentsBloc({required RouteAssignmentRepository repository})
      : _repository = repository,
        super(const StudentAssignmentsState()) {
    on<StudentAssignmentsRequested>(_onRequested);
    on<StudentAssignmentAdded>(_onAdded);
    on<StudentAssignmentRemoved>(_onRemoved);
  }

  final RouteAssignmentRepository _repository;

  Future<void> _onRequested(
      StudentAssignmentsRequested event, Emitter<StudentAssignmentsState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listForStudent(studentId: event.studentId);

    switch (result) {
      case Success<List<RouteAssignment>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, assignments: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onAdded(
      StudentAssignmentAdded event, Emitter<StudentAssignmentsState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.assign(
      routeId: event.routeId,
      studentId: event.studentId,
      stopId: event.stopId,
      direction: event.direction,
    );

    switch (result) {
      case Success<RouteAssignment>():
        // Re-list so the panel shows the authoritative pickup/drop pair, rather than
        // reconciling a possible replacement of an existing same-direction assignment locally.
        await _reload(event.studentId, emit);
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onRemoved(
      StudentAssignmentRemoved event, Emitter<StudentAssignmentsState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.remove(assignmentId: event.assignmentId);

    switch (result) {
      case Success<void>():
        await _reload(event.studentId, emit);
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _reload(String studentId, Emitter<StudentAssignmentsState> emit) async {
    final result = await _repository.listForStudent(studentId: studentId);
    switch (result) {
      case Success<List<RouteAssignment>>(:final value):
        emit(state.copyWith(isSubmitting: false, clearError: true, assignments: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
