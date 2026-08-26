import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/platform_health_bloc.dart';
import '../bloc/platform_health_event.dart';
import 'platform_health_screen.dart';

/// Composes the Platform health feature (A-62) — matching `OrganizationListRoute`'s split:
/// the route owns the wiring, the screen owns none of it.
class PlatformHealthRoute extends StatelessWidget {
  const PlatformHealthRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<PlatformHealthBloc>(
      create: (_) => PlatformHealthBloc(
        repository: dependencies.platformHealthRepository,
      )..add(const PlatformHealthRequested()),
      child: const PlatformHealthScreen(),
    );
  }
}
