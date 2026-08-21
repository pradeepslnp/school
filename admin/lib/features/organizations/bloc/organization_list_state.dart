import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/onboarding_models.dart';

/// The Organizations list screen (A-41), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `OrganizationOnboardingState` and
/// `LoginState` — every field the screen renders is here.
class OrganizationListState extends Equatable {
  const OrganizationListState({
    this.isLoading = false,
    this.organizations = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final List<CreatedOrganization> organizations;

  /// The last failure, or null.
  final ErrorCode? error;
  final String? errorMessageKey;

  OrganizationListState copyWith({
    bool? isLoading,
    List<CreatedOrganization>? organizations,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return OrganizationListState(
      isLoading: isLoading ?? this.isLoading,
      organizations: organizations ?? this.organizations,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, organizations, error, errorMessageKey];
}
