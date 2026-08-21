import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../../organizations/domain/onboarding_models.dart';

/// The School screen (A-41), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `StaffListState` — every field the
/// screen renders is here.
class SchoolSettingsState extends Equatable {
  const SchoolSettingsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.school,
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;

  /// Null until the school loads. Unlike `StaffListState.staff`, this screen has exactly one
  /// record — no empty-list state to distinguish from not-yet-loaded.
  final CreatedSchool? school;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  SchoolSettingsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    CreatedSchool? school,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return SchoolSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      school: school ?? this.school,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSubmitting, school, error, errorMessageKey];
}
