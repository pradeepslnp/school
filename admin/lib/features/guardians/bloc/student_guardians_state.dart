import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/guardian_models.dart';

/// The guardians panel for one student (A-11), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `StaffListState` — every field the
/// panel renders is here.
class StudentGuardiansState extends Equatable {
  const StudentGuardiansState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.guardians = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<StudentGuardian> guardians;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  /// Whether at least one guardian can actually receive the child (BR-GRD-002). The panel
  /// surfaces this because a student with none cannot be assigned to a bus, and the operator
  /// should see why before they reach the pickup/drop step.
  bool get hasHandoverGuardian => guardians.any((g) => g.canAuthoriseHandover);

  StudentGuardiansState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<StudentGuardian>? guardians,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return StudentGuardiansState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      guardians: guardians ?? this.guardians,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSubmitting, guardians, error, errorMessageKey];
}
