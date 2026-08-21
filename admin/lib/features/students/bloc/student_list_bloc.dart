import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/student_models.dart';
import '../repository/student_repository.dart';
import 'student_list_event.dart';
import 'student_list_state.dart';

/// The student register for one school (A-10, STU-001).
///
/// Depends on a repository only, never a data provider — matching `StaffListBloc`, so this is
/// tested with no HTTP and no fake server.
class StudentListBloc extends Bloc<StudentListEvent, StudentListState> {
  StudentListBloc({required StudentRepository repository})
      : _repository = repository,
        super(const StudentListState()) {
    on<StudentListRequested>(_onRequested);
    on<StudentListNextPageRequested>(_onNextPageRequested);
    on<StudentCreated>(_onCreated);
    on<StudentUpdated>(_onUpdated);
    on<StudentWithdrawn>(_onWithdrawn);
  }

  final StudentRepository _repository;

  Future<void> _onRequested(
    StudentListRequested event,
    Emitter<StudentListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listStudents(schoolId: event.schoolId);

    switch (result) {
      case Success<StudentPage>(:final value):
        emit(state.copyWith(
          isLoading: false,
          clearError: true,
          clearCursor: true,
          students: value.students,
          nextCursor: value.nextCursor,
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onNextPageRequested(
    StudentListNextPageRequested event,
    Emitter<StudentListState> emit,
  ) async {
    // Guarded rather than queued: a scroll listener fires repeatedly at the bottom of a list,
    // and without this the same page would be requested several times and appended twice.
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final result = await _repository.listStudents(
      schoolId: event.schoolId,
      cursor: state.nextCursor,
    );

    switch (result) {
      case Success<StudentPage>(:final value):
        emit(state.copyWith(
          isLoadingMore: false,
          clearError: true,
          clearCursor: true,
          students: [...state.students, ...value.students],
          nextCursor: value.nextCursor,
        ));
      case Failure(:final code, :final messageKey):
        // The rows already loaded stay on screen. A failed next page is a failure to extend
        // the list, not a reason to discard what the operator is reading.
        emit(state.copyWith(
          isLoadingMore: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }

  Future<void> _onCreated(StudentCreated event, Emitter<StudentListState> emit) async {
    if (event.schoolId.trim().isEmpty ||
        event.admissionNo.trim().isEmpty ||
        event.firstName.trim().isEmpty ||
        event.lastName.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.createStudent(
      schoolId: event.schoolId,
      admissionNo: event.admissionNo,
      firstName: event.firstName,
      lastName: event.lastName,
      dateOfBirth: event.dateOfBirth,
      transportEligible: event.transportEligible,
    );

    switch (result) {
      case Success<Student>(:final value):
        // Inserted in admission-number order rather than prepended, because that is the order
        // the register is paged in — a new row at the top would sit where the cursor says a
        // different student belongs, and jump on the next refresh.
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          students: _insertInOrder(state.students, value),
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onUpdated(StudentUpdated event, Emitter<StudentListState> emit) async {
    if (event.firstName.trim().isEmpty || event.lastName.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.updateStudent(
      studentId: event.studentId,
      firstName: event.firstName,
      lastName: event.lastName,
      dateOfBirth: event.dateOfBirth,
      transportEligible: event.transportEligible,
    );

    _emitReplacement(result, emit);
  }

  Future<void> _onWithdrawn(StudentWithdrawn event, Emitter<StudentListState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.withdrawStudent(
      studentId: event.studentId,
      reason: event.reason,
    );

    // The row is replaced, not removed. A withdrawn student stays visible with their status
    // shown — BR-STU-005 keeps the record, and hiding it would suggest to the office that the
    // child had been deleted.
    _emitReplacement(result, emit);
  }

  void _emitReplacement(Result<Student> result, Emitter<StudentListState> emit) {
    switch (result) {
      case Success<Student>(:final value):
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          students: [
            for (final student in state.students)
              if (student.id == value.id) value else student,
          ],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  static List<Student> _insertInOrder(List<Student> existing, Student added) {
    final students = [...existing];
    final index = students.indexWhere(
      (student) => student.admissionNo.compareTo(added.admissionNo) > 0,
    );
    if (index < 0) {
      students.add(added);
    } else {
      students.insert(index, added);
    }
    return students;
  }
}
