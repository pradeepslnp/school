import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/route_list_bloc.dart';
import 'route_list_screen.dart';

/// Composes the Routes feature (A-30) — matching `VehicleListRoute`'s split: the route owns
/// the wiring, the screen owns none of it.
class RouteListRoute extends StatelessWidget {
  const RouteListRoute({super.key, this.initialSchoolId});

  final String? initialSchoolId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<RouteListBloc>(
      create: (_) => RouteListBloc(repository: dependencies.routeRepository),
      child: RouteListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
