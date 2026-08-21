import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/duty_assignment_models.dart';

/// The crew-assignment dialog for one route (STF-004), including its loading and error
/// conditions. One state class rather than a family of them, matching `RouteListState`.
class DutyAssignmentState extends Equatable {
  const DutyAssignmentState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.assignments = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<CreatedDutyAssignment> assignments;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  DutyAssignmentState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<CreatedDutyAssignment>? assignments,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return DutyAssignmentState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      assignments: assignments ?? this.assignments,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSubmitting, assignments, error, errorMessageKey];
}
