import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/organization_onboarding_bloc.dart';
import '../bloc/organization_onboarding_event.dart';
import '../domain/onboarding_models.dart';
import 'organization_onboarding_screen.dart';

/// Composes the organization-onboarding feature — matching `LoginRoute`'s split: the route
/// owns the wiring, the screen owns none of it.
///
/// [viewingOrganization] is set when this is reached from the Organizations list (A-41) rather
/// than as a fresh "add organization" flow — the bloc jumps straight to the details/edit step
/// for that organization instead of starting at step 1.
class OrganizationOnboardingRoute extends StatelessWidget {
  const OrganizationOnboardingRoute({
    super.key,
    required this.actorRoles,
    required this.actorOrganizationId,
    this.viewingOrganization,
  });

  /// Passed straight through to `OrganizationOnboardingScreen` — see its own documentation.
  final List<String> actorRoles;

  /// Passed straight through alongside [actorRoles].
  final String? actorOrganizationId;

  final CreatedOrganization? viewingOrganization;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);
    final viewing = viewingOrganization;

    return BlocProvider<OrganizationOnboardingBloc>(
      create: (_) {
        final bloc = OrganizationOnboardingBloc(
          repository: dependencies.organizationOnboardingRepository,
        );
        if (viewing != null) {
          bloc.add(OrganizationSelectedForViewing(organization: viewing));
        }
        return bloc;
      },
      child: OrganizationOnboardingScreen(
        actorRoles: actorRoles,
        actorOrganizationId: actorOrganizationId,
      ),
    );
  }
}
