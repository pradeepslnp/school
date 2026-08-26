import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/route_assignment_models.dart';

/// The pickup/drop panel for one student (RTE-003), including its loading and error conditions.
class StudentAssignmentsState extends Equatable {
  const StudentAssignmentsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.assignments = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<RouteAssignment> assignments;

  final ErrorCode? error;
  final String? errorMessageKey;

  /// The active pickup assignment, or null. At most one exists (BR-ROUTE-004).
  RouteAssignment? get pickup => _firstWhereOrNull((a) => a.isPickup);

  /// The active drop assignment, or null. At most one exists (BR-ROUTE-004).
  RouteAssignment? get drop => _firstWhereOrNull((a) => a.isDrop);

  RouteAssignment? _firstWhereOrNull(bool Function(RouteAssignment) test) {
    for (final assignment in assignments) {
      if (test(assignment)) return assignment;
    }
    return null;
  }

  StudentAssignmentsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<RouteAssignment>? assignments,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return StudentAssignmentsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      assignments: assignments ?? this.assignments,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSubmitting, assignments, error, errorMessageKey];
}
