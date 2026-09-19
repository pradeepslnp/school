import 'package:equatable/equatable.dart';

/// What the operator did on the student register (A-10).
sealed class StudentListEvent extends Equatable {
  const StudentListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown, or the operator asked to refresh, for one school's register.
final class StudentListRequested extends StudentListEvent {
  const StudentListRequested({required this.schoolId});

  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}

/// The operator reached the end of the loaded rows and wants the next page.
final class StudentListNextPageRequested extends StudentListEvent {
  const StudentListNextPageRequested({required this.schoolId});

  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}

/// The operator enrolled a student (STU-001).
final class StudentCreated extends StudentListEvent {
  const StudentCreated({
    required this.schoolId,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.transportEligible,
  });

  final String schoolId;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final bool? transportEligible;

  @override
  List<Object?> get props =>
      [schoolId, admissionNo, firstName, lastName, dateOfBirth, transportEligible];
}

/// The operator saved changes to a student's details (STU-001).
///
/// No `admissionNo` and no `schoolId` — see `StudentDataProvider.updateStudent` for why neither
/// is offered as an edit.
final class StudentUpdated extends StudentListEvent {
  const StudentUpdated({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.transportEligible,
  });

  final String studentId;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final bool? transportEligible;

  @override
  List<Object?> get props =>
      [studentId, firstName, lastName, dateOfBirth, transportEligible];
}

/// The operator took a student off the roll (STU-004). Confirmed in the UI first — this is a
/// state change other people's screens depend on, not an ordinary edit.
final class StudentWithdrawn extends StudentListEvent {
  const StudentWithdrawn({required this.studentId, this.reason});

  final String studentId;
  final String? reason;

  @override
  List<Object?> get props => [studentId, reason];
}

/// The operator deleted a student entered by mistake (STU-008, ADR-0019). Confirmed in the UI
/// with a required reason first — this cannot be undone.
final class StudentDiscarded extends StudentListEvent {
  const StudentDiscarded({required this.studentId, required this.reason});

  final String studentId;
  final String reason;

  @override
  List<Object?> get props => [studentId, reason];
}
