import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/domain/onboarding_models.dart';
import '../../organizations/ui/organization_onboarding_route.dart';
import '../../students/domain/student_models.dart';
import '../../students/ui/student_detail_route.dart';
import '../bloc/global_search_bloc.dart';
import '../domain/search_models.dart';
import '../widgets/global_search_field.dart';

/// Composes global search (SRC-001) for the console header, and owns where a chosen result leads.
///
/// Matching the other routes' split: the route owns the wiring and the navigation, the field owns
/// neither. Navigation stays within what the console already offers — a result opens the screen
/// that record already has, never a new one, and only a destination the signed-in roles can reach
/// (see `ConsoleRouterDelegate`'s location handling).
class GlobalSearchRoute extends StatelessWidget {
  const GlobalSearchRoute({
    super.key,
    required this.actorRoles,
    required this.actorOrganizationId,
    required this.onGoToLocation,
  });

  /// The console roles holding `PERM-SEARCH-QUERY` (PERMISSION_MATRIX.md §Search). Affordance
  /// only — the server refuses the endpoint to anyone else regardless.
  static const Set<String> _searchRoles = {
    'SUPER_ADMIN',
    'ORG_ADMIN',
    'SCHOOL_ADMIN',
    'PRINCIPAL',
    'TRANSPORT_MANAGER',
  };

  /// Whether the header should offer search to an operator holding [roles].
  static bool isAvailableTo(List<String> roles) => roles.any(_searchRoles.contains);

  final List<String> actorRoles;

  /// Passed through to `OrganizationOnboardingRoute` when an organization result is opened.
  final String? actorOrganizationId;

  /// Moves the console to a destination location. False when the signed-in roles cannot reach it.
  final bool Function(String location) onGoToLocation;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<GlobalSearchBloc>(
      create: (_) => GlobalSearchBloc(repository: dependencies.searchRepository),
      child: GlobalSearchField(onSelected: (hit) => _open(context, hit)),
    );
  }

  Future<void> _open(BuildContext context, SearchHit hit) async {
    final dependencies = DependencyScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final openFailed = context.l10n.globalSearchOpenFailed;
    final noScreen = context.l10n.globalSearchNoScreen;

    // A platform operator's search spans organizations (ADR-0018), and the record a result opens
    // lives in one of them — so the console enters it first, through the same audited elevation
    // every other cross-organization screen uses (ADR-0016). Everyone else's results carry no
    // organization: they are already in their own.
    final organizationId = hit.organizationId;
    if (organizationId != null) {
      dependencies.actingOrganization.enter(organizationId);
    }

    Future<void> openStudent(String studentId) async {
      final result = await dependencies.studentRepository.getStudent(studentId: studentId);
      switch (result) {
        case Success<Student>(:final value):
          navigator.push(
            MaterialPageRoute<void>(builder: (_) => StudentDetailRoute(student: value)),
          );
        case Failure():
          messenger.showSnackBar(SnackBar(content: Text(openFailed)));
      }
    }

    // Search follows the permission matrix, the rail follows ConsoleDestinations, and the two do
    // not always agree — a PRINCIPAL may view vehicles but has no Vehicles screen. Such a result
    // says so rather than doing nothing when chosen.
    void goTo(String location) {
      if (!onGoToLocation(location)) {
        messenger.showSnackBar(SnackBar(content: Text(noScreen)));
      }
    }

    // The Drivers, Vehicles, Routes and Students screens load the school the workspace remembers,
    // so a result from another school lands on that school's list.
    void openAtSchool(String location, String? schoolId) {
      if (schoolId != null) dependencies.workspaceContext.value = schoolId;
      goTo(location);
    }

    switch (hit.type) {
      case SearchResultType.student:
        await openStudent(hit.id);
      case SearchResultType.guardian:
        // Parents are managed on their child's record, which is where their row leads.
        final studentId = hit.relatedStudentId;
        if (studentId != null) await openStudent(studentId);
      case SearchResultType.staff:
        openAtSchool('/staff', hit.schoolId);
      case SearchResultType.vehicle:
        openAtSchool('/vehicles', hit.schoolId);
      case SearchResultType.route:
        openAtSchool('/routes', hit.schoolId);
      case SearchResultType.user:
        goTo('/users');
      case SearchResultType.school:
        // A school admin's own school has a screen of its own; anyone else lands on its register.
        if (!onGoToLocation('/school')) openAtSchool('/students', hit.id);
      case SearchResultType.organization:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => OrganizationOnboardingRoute(
              actorRoles: actorRoles,
              actorOrganizationId: actorOrganizationId,
              viewingOrganization: CreatedOrganization(
                id: hit.id,
                code: hit.code ?? '',
                name: hit.title,
                regionProfileCode: hit.kind ?? '',
                status: hit.status ?? 'ACTIVE',
              ),
            ),
          ),
        );
      case SearchResultType.unknown:
        break;
    }
  }
}
