import 'package:equatable/equatable.dart';

import '../../../../core/domain.dart';
import '../domain/student_import_models.dart';

/// Where the operator is in a bulk import (A-12).
enum StudentImportPhase {
  /// Waiting for a file to be chosen, or ready to choose another.
  choosing,

  /// The file is uploading and being processed.
  uploading,

  /// A file has been processed — [StudentImportState.result] holds the outcome.
  done,
}

/// The bulk import screen (A-12), including its uploading and error conditions.
///
/// One state class rather than a family, matching the other features here.
class StudentImportState extends Equatable {
  const StudentImportState({
    this.phase = StudentImportPhase.choosing,
    this.fileName,
    this.result,
    this.error,
    this.errorMessageKey,
    this.errorBusinessRule,
  });

  final StudentImportPhase phase;

  /// The name of the file being uploaded or just processed — shown so the operator can see
  /// which upload a result belongs to.
  final String? fileName;

  final StudentImportResult? result;

  /// A whole-file rejection, or a transport failure. Per-row failures are not errors — they
  /// live in [result].
  final ErrorCode? error;
  final String? errorMessageKey;
  final String? errorBusinessRule;

  bool get isUploading => phase == StudentImportPhase.uploading;

  /// At least one student was enrolled — the register behind this screen is now stale.
  bool get importedAnything => (result?.successCount ?? 0) > 0;

  StudentImportState copyWith({
    StudentImportPhase? phase,
    String? fileName,
    StudentImportResult? result,
    ErrorCode? error,
    String? errorMessageKey,
    String? errorBusinessRule,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return StudentImportState(
      phase: phase ?? this.phase,
      fileName: fileName ?? this.fileName,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError
          ? null
          : (errorMessageKey ?? this.errorMessageKey),
      errorBusinessRule: clearError
          ? null
          : (errorBusinessRule ?? this.errorBusinessRule),
    );
  }

  @override
  List<Object?> get props => [
    phase,
    fileName,
    result,
    error,
    errorMessageKey,
    errorBusinessRule,
  ];
}
