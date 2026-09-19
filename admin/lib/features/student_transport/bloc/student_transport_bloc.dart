import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/student_transport_models.dart';
import '../repository/student_transport_repository.dart';
import 'student_transport_event.dart';
import 'student_transport_state.dart';

/// Reads a student's assigned bus and crew (A-11, STU-009).
///
/// Depends on a repository only, never a data provider — matching `StudentAssignmentsBloc`.
class StudentTransportBloc extends Bloc<StudentTransportEvent, StudentTransportState> {
  StudentTransportBloc({required StudentTransportRepository repository})
    : _repository = repository,
      super(const StudentTransportState()) {
    on<StudentTransportRequested>(_onRequested);
  }

  final StudentTransportRepository _repository;

  Future<void> _onRequested(
    StudentTransportRequested event,
    Emitter<StudentTransportState> emit,
  ) async {
    // The last good answer stays on screen while a refresh runs — a pickup change should not
    // blank the panel the operator is reading.
    emit(StudentTransportState(isLoading: true, transport: state.transport));

    final result = await _repository.getTransport(studentId: event.studentId);

    switch (result) {
      case Success<StudentTransport>(:final value):
        emit(StudentTransportState(transport: value));
      case Failure(:final code):
        emit(StudentTransportState(transport: state.transport, error: code));
    }
  }
}
