import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/organization_list_bloc.dart';
import '../bloc/organization_list_event.dart';
import '../domain/onboarding_models.dart';
import 'organization_list_screen.dart';
import 'organization_onboarding_route.dart';

/// Composes the Organizations list feature (A-41) — matching `OrganizationOnboardingRoute`'s
/// split: the route owns the wiring and the navigation, the screen owns neither.
///
/// Pushing to create or view an organization is a plain [Navigator] push rather than a new
/// console location: `ConsoleRouterDelegate._screenFor` renders exactly one screen per
/// location today, and both destinations here return to this same list, so there is nothing a
/// URL would add that a back button does not already give the operator.
class OrganizationListRoute extends StatelessWidget {
  const OrganizationListRoute({super.key, required this.actorRoles});

  /// Passed straight through to `OrganizationOnboardingRoute` when the operator opens an
  /// organization — see `OrganizationDetailsView._canManageLifecycle`.
  final List<String> actorRoles;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<OrganizationListBloc>(
      create: (_) => OrganizationListBloc(
        repository: dependencies.organizationOnboardingRepository,
      ),
      child: Builder(
        builder: (context) => OrganizationListScreen(
          onAddOrganization: () => _openOnboarding(context),
          onOpenOrganization: (organization) => _openOnboarding(context, viewing: organization),
        ),
      ),
    );
  }

  Future<void> _openOnboarding(
    BuildContext context, {
    CreatedOrganization? viewing,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OrganizationOnboardingRoute(
          actorRoles: actorRoles,
          viewingOrganization: viewing,
        ),
      ),
    );
    if (context.mounted) {
      // The operator may have created, edited, or added a school to an organization on the
      // pushed screen — refresh so the list reflects it on return, rather than showing what
      // was true before they left.
      context.read<OrganizationListBloc>().add(const OrganizationListRequested());
    }
  }
}
