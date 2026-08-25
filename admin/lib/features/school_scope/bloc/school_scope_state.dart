import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../../organizations/domain/onboarding_models.dart';

/// The school picker shared by every school-scoped list screen (Students, Drivers, Vehicles,
/// Routes) — see `SchoolPickerField`.
///
/// One state class covering both the organization step and the school step, matching
/// `OrganizationListState`'s discipline of one class per screen's worth of state rather than a
/// family of them: [showOrganizationPicker] is the only branch the widget needs.
class SchoolScopeState extends Equatable {
  const SchoolScopeState({
    this.showOrganizationPicker = false,
    this.isLoadingOrganizations = false,
    this.organizations = const [],
    this.selectedOrganizationId,
    this.isLoadingSchools = false,
    this.schools = const [],
    this.selectedSchoolId,
    this.error,
    this.errorMessageKey,
  });

  /// Whether the operator must pick an organization before a school — false for an
  /// `ORG_ADMIN`, who has exactly one and goes straight to its schools.
  final bool showOrganizationPicker;

  final bool isLoadingOrganizations;
  final List<CreatedOrganization> organizations;
  final String? selectedOrganizationId;

  final bool isLoadingSchools;
  final List<CreatedSchool> schools;

  /// The school the picker has resolved — chosen by the operator, or, when a fetched list
  /// holds exactly one school, chosen automatically (`SchoolScopeBloc._loadSchools`). Null
  /// until one exists.
  final String? selectedSchoolId;

  /// The last failure, or null.
  final ErrorCode? error;
  final String? errorMessageKey;

  SchoolScopeState copyWith({
    bool? showOrganizationPicker,
    bool? isLoadingOrganizations,
    List<CreatedOrganization>? organizations,
    String? selectedOrganizationId,
    bool? isLoadingSchools,
    List<CreatedSchool>? schools,
    String? selectedSchoolId,
    bool clearSelectedSchoolId = false,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return SchoolScopeState(
      showOrganizationPicker: showOrganizationPicker ?? this.showOrganizationPicker,
      isLoadingOrganizations: isLoadingOrganizations ?? this.isLoadingOrganizations,
      organizations: organizations ?? this.organizations,
      selectedOrganizationId: selectedOrganizationId ?? this.selectedOrganizationId,
      isLoadingSchools: isLoadingSchools ?? this.isLoadingSchools,
      schools: schools ?? this.schools,
      selectedSchoolId:
          clearSelectedSchoolId ? null : (selectedSchoolId ?? this.selectedSchoolId),
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [
        showOrganizationPicker,
        isLoadingOrganizations,
        organizations,
        selectedOrganizationId,
        isLoadingSchools,
        schools,
        selectedSchoolId,
        error,
        errorMessageKey,
      ];
}
  