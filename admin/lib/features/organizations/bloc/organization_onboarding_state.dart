import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/onboarding_models.dart';

/// Where the operator is in the two-step onboarding flow.
enum OnboardingStep {
  /// Entering the organization's own details (TEN-001).
  organizationDetails,

  /// The organization exists; entering its first school's details (TEN-002).
  schoolDetails,

  /// Either step 2 succeeded, or the operator chose to skip it. Onboarding is done.
  complete,
}

/// The whole organization-onboarding screen, including its loading and error conditions.
///
/// One state class rather than a family of them, matching `LoginState` — every field the
/// screen renders is here, so there is no combination the widget can be handed that it has
/// not been written for.
class OrganizationOnboardingState extends Equatable {
  const OrganizationOnboardingState({
    this.step = OnboardingStep.organizationDetails,
    this.isSubmitting = false,
    this.error,
    this.errorMessageKey,
    this.organization,
    this.school,
  });

  final OnboardingStep step;
  final bool isSubmitting;

  /// The last failure, or null. Cleared whenever a new submission starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  /// Set once step 1 succeeds. Read by the widget for the confirmation banner on step 2, and
  /// by the bloc for the `organizationId` step 2 needs to submit.
  final CreatedOrganization? organization;

  /// Set once step 2 succeeds. Null if the operator skipped it.
  final CreatedSchool? school;

  bool get canSubmit => !isSubmitting;

  OrganizationOnboardingState copyWith({
    OnboardingStep? step,
    bool? isSubmitting,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
    CreatedOrganization? organization,
    CreatedSchool? school,
    // Plain `school: null` cannot distinguish "leave it as it was" from "this organization has
    // none" because of the `??` fallback below — the same reason `clearError` exists rather
    // than relying on `error: null`. Needed once the screen can move between two different
    // organizations in one bloc lifetime (A-41): without it, an organization with no school
    // would keep showing the previous organization's.
    bool clearSchool = false,
  }) {
    return OrganizationOnboardingState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
      organization: organization ?? this.organization,
      school: clearSchool ? null : (school ?? this.school),
    );
  }

  @override
  List<Object?> get props =>
      [step, isSubmitting, error, errorMessageKey, organization, school];
}
