import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../school_scope/bloc/school_scope_bloc.dart';
import '../../school_scope/bloc/school_scope_event.dart';
import '../bloc/route_list_bloc.dart';
import 'route_list_screen.dart';

/// Composes the Routes feature (A-30) — matching `VehicleListRoute`'s split: the route owns
/// the wiring, the screen owns none of it.
class RouteListRoute extends StatelessWidget {
  const RouteListRoute({super.key, this.initialSchoolId, this.initialOrganizationId});

  final String? initialSchoolId;

  /// See `StudentListRoute.initialOrganizationId` — same reasoning, same source.
  final String? initialOrganizationId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<RouteListBloc>(
          create: (_) => RouteListBloc(repository: dependencies.routeRepository),
        ),
        if (initialSchoolId == null)
          BlocProvider<SchoolScopeBloc>(
            create: (_) => SchoolScopeBloc(
              repository: dependencies.organizationOnboardingRepository,
              actingOrganization: dependencies.actingOrganization,
            )..add(SchoolScopeStarted(organizationScopeId: initialOrganizationId)),
          ),
      ],
      child: RouteListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
