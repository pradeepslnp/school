import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/staff_models.dart';

/// The Drivers screen (A-23), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `OrganizationListState` — every
/// field the screen renders is here.
class StaffListState extends Equatable {
  const StaffListState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.staff = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<CreatedStaff> staff;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  StaffListState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<CreatedStaff>? staff,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return StaffListState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      staff: staff ?? this.staff,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSubmitting, staff, error, errorMessageKey];
}
