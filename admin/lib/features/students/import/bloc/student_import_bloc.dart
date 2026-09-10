import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain.dart';
import '../domain/student_import_models.dart';
import '../repository/student_import_repository.dart';
import 'student_import_event.dart';
import 'student_import_state.dart';

/// Uploads a spreadsheet of students and reports the per-row outcome (A-12, STU-002).
///
/// Depends on a repository only. Choosing the file and saving the error report are browser
/// operations the screen performs directly through the file gateway — this bloc never sees a
/// browser type, and starts only once bytes are in hand.
class StudentImportBloc extends Bloc<StudentImportEvent, StudentImportState> {
  StudentImportBloc({required StudentImportRepository repository})
    : _repository = repository,
      super(const StudentImportState()) {
    on<StudentImportSubmitted>(_onSubmitted);
    on<StudentImportReset>(_onReset);
  }

  final StudentImportRepository _repository;

  Future<void> _onSubmitted(
    StudentImportSubmitted event,
    Emitter<StudentImportState> emit,
  ) async {
    if (event.schoolId.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(
      state.copyWith(
        phase: StudentImportPhase.uploading,
        fileName: event.file.name,
        clearError: true,
        clearResult: true,
      ),
    );

    final result = await _repository.importCsv(
      schoolId: event.schoolId,
      file: event.file,
    );

    switch (result) {
      case Success<StudentImportResult>(:final value):
        emit(
          state.copyWith(
            phase: StudentImportPhase.done,
            result: value,
            clearError: true,
          ),
        );
      case Failure<StudentImportResult>(
        :final code,
        :final messageKey,
        :final businessRule,
      ):
        emit(
          state.copyWith(
            phase: StudentImportPhase.choosing,
            error: code,
            errorMessageKey: messageKey,
            errorBusinessRule: businessRule,
          ),
        );
    }
  }

  void _onReset(StudentImportReset event, Emitter<StudentImportState> emit) {
    emit(const StudentImportState());
  }
}
