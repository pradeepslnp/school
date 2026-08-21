import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/student_models.dart';

/// The student register (A-10), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `StaffListState` — every field the
/// screen renders is here.
///
/// [isLoadingMore] is separate from [isLoading] on purpose: fetching the next page must not
/// blank the rows already on screen. An operator scrolling a register of two thousand children
/// should never watch the list they are reading disappear.
class StudentListState extends Equatable {
  const StudentListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.students = const [],
    this.nextCursor,
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final List<Student> students;

  /// Cursor for the page after the rows currently held; null when the register is fully loaded.
  final String? nextCursor;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  bool get hasMore => nextCursor != null;

  StudentListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    List<Student>? students,
    String? nextCursor,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return StudentListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      students: students ?? this.students,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingMore,
        isSubmitting,
        students,
        nextCursor,
        error,
        errorMessageKey,
      ];
}
