import 'package:equatable/equatable.dart';

/// What the operator did while picking which school's data to load, on any of the
/// school-scoped list screens (Students, Drivers, Vehicles, Routes) — see `SchoolPickerField`.
sealed class SchoolScopeEvent extends Equatable {
  const SchoolScopeEvent();

  @override
  List<Object?> get props => const [];
}

/// The picker was shown. [organizationScopeId] is the signed-in operator's own organization
/// (`AuthenticatedUser.organizationScopeId`) when they hold one — an `ORG_ADMIN` goes straight
/// to that organization's schools; a `SUPER_ADMIN`, who holds no single-organization scope,
/// picks an organization first.
final class SchoolScopeStarted extends SchoolScopeEvent {
  const SchoolScopeStarted({this.organizationScopeId});

  final String? organizationScopeId;

  @override
  List<Object?> get props => [organizationScopeId];
}

/// The operator picked an organization — shown only when [SchoolScopeState.showOrganizationPicker].
final class SchoolScopeOrganizationSelected extends SchoolScopeEvent {
  const SchoolScopeOrganizationSelected(this.organizationId);

  final String organizationId;

  @override
  List<Object?> get props => [organizationId];
}

/// The operator picked a school from the dropdown. Also raised by nothing external when a
/// fetched list holds exactly one school — see `SchoolScopeBloc._loadSchools`, which resolves
/// that case by emitting [SchoolScopeState.selectedSchoolId] directly rather than by routing
/// through this event, since there is no operator action to represent.
final class SchoolScopeSchoolSelected extends SchoolScopeEvent {
  const SchoolScopeSchoolSelected(this.schoolId);

  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}
