import 'package:equatable/equatable.dart';

import '../domain/onboarding_models.dart';

/// What the operator did on the organization-onboarding screen.
///
/// Never what the app should do next — matching `LoginEvent`'s discipline
/// (CODING_STANDARDS_FLUTTER.md §Layering).
sealed class OrganizationOnboardingEvent extends Equatable {
  const OrganizationOnboardingEvent();

  @override
  List<Object?> get props => const [];
}

/// The operator submitted the organization details (step 1, TEN-001).
final class OrganizationDetailsSubmitted extends OrganizationOnboardingEvent {
  const OrganizationDetailsSubmitted({
    required this.code,
    required this.name,
    required this.regionProfileCode,
    this.contactEmail,
    this.contactPhone,
  });

  final String code;
  final String name;
  final String regionProfileCode;
  final String? contactEmail;
  final String? contactPhone;

  @override
  List<Object?> get props =>
      [code, name, regionProfileCode, contactEmail, contactPhone];
}

/// The operator submitted the first school's details (step 2, TEN-002).
///
/// Only reachable once [OrganizationDetailsSubmitted] has succeeded — the bloc, not this
/// event, carries which organization the school belongs to
/// (CODING_STANDARDS_FLUTTER.md §Layering: the widget reports what happened, not the state
/// it depends on).
final class SchoolDetailsSubmitted extends OrganizationOnboardingEvent {
  const SchoolDetailsSubmitted({
    required this.code,
    required this.name,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusM,
  });

  final String code;
  final String name;
  final String timezone;
  final double latitude;
  final double longitude;
  final int geofenceRadiusM;

  @override
  List<Object?> get props =>
      [code, name, timezone, latitude, longitude, geofenceRadiusM];
}

/// The operator edited the organization's details from the details view, after it already
/// exists (`PATCH /organizations/{id}`). No `code`: it is immutable (BR-TEN-007).
final class OrganizationDetailsEdited extends OrganizationOnboardingEvent {
  const OrganizationDetailsEdited({
    required this.name,
    required this.regionProfileCode,
    this.contactEmail,
    this.contactPhone,
  });

  final String name;
  final String regionProfileCode;
  final String? contactEmail;
  final String? contactPhone;

  @override
  List<Object?> get props => [name, regionProfileCode, contactEmail, contactPhone];
}

/// The operator edited the school's details from the details view, after it already exists
/// (`PATCH /schools/{id}`). No `code`, for the same reason as [OrganizationDetailsEdited].
final class SchoolDetailsEdited extends OrganizationOnboardingEvent {
  const SchoolDetailsEdited({
    required this.name,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusM,
  });

  final String name;
  final String timezone;
  final double latitude;
  final double longitude;
  final int geofenceRadiusM;

  @override
  List<Object?> get props => [name, timezone, latitude, longitude, geofenceRadiusM];
}

/// The operator opened an organization from the list screen (A-41) rather than having just
/// created it in this session.
///
/// Carries the organization as already returned by `GET /organizations` — a second round trip
/// to re-fetch the same row it just came from would be redundant. The bloc still has to look up
/// the organization's school separately: the list endpoint returns organizations only, not
/// their schools (TEN-002).
final class OrganizationSelectedForViewing extends OrganizationOnboardingEvent {
  const OrganizationSelectedForViewing({required this.organization});

  final CreatedOrganization organization;

  @override
  List<Object?> get props => [organization];
}

/// The operator chose to finish onboarding without adding a school yet.
///
/// A real choice, not a shortcut: BR-TEN-002 only requires a school before the organization
/// can be *used*, not before it can exist, and an operator onboarding several organizations
/// in one sitting may reasonably want to add schools afterwards from a dedicated screen once
/// one exists (A-41).
final class SchoolStepSkipped extends OrganizationOnboardingEvent {
  const SchoolStepSkipped();
}

/// The operator asked to onboard another organization after completing one.
final class OnboardingReset extends OrganizationOnboardingEvent {
  const OnboardingReset();
}
