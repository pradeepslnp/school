import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/custody_restriction_models.dart';

/// The custody-restrictions panel for one student (A-14), including loading and error
/// conditions. One state class, matching the other panels on this screen.
class StudentCustodyState extends Equatable {
  const StudentCustodyState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.restrictions = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<CustodyRestriction> restrictions;

  /// The last failure, or null. Cleared when a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  /// Any restriction currently in force — the panel and the student header both flag this,
  /// because it changes who may collect and see the child right now.
  bool get hasActiveRestriction => restrictions.any((r) => r.active);

  StudentCustodyState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<CustodyRestriction>? restrictions,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return StudentCustodyState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      restrictions: restrictions ?? this.restrictions,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSubmitting, restrictions, error, errorMessageKey];
}
