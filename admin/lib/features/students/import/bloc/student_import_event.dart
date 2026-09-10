import 'package:equatable/equatable.dart';

import '../domain/student_import_models.dart';

/// What the operator did on the bulk import screen (A-12).
sealed class StudentImportEvent extends Equatable {
  const StudentImportEvent();

  @override
  List<Object?> get props => const [];
}

/// The operator chose a file and it has been read into memory — upload it.
final class StudentImportSubmitted extends StudentImportEvent {
  const StudentImportSubmitted({required this.schoolId, required this.file});

  final String schoolId;
  final PickedCsv file;

  @override
  List<Object?> get props => [schoolId, file];
}

/// The operator asked to import another file — clears the last result.
final class StudentImportReset extends StudentImportEvent {
  const StudentImportReset();
}
