import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../school_scope/bloc/school_scope_bloc.dart';
import '../../school_scope/bloc/school_scope_event.dart';
import '../bloc/vehicle_list_bloc.dart';
import 'vehicle_list_screen.dart';

/// Composes the Vehicles feature (A-20) — matching `StaffListRoute`'s split: the route owns
/// the wiring, the screen owns none of it.
class VehicleListRoute extends StatelessWidget {
  const VehicleListRoute({super.key, this.initialSchoolId, this.initialOrganizationId});

  final String? initialSchoolId;

  /// See `StudentListRoute.initialOrganizationId` — same reasoning, same source.
  final String? initialOrganizationId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<VehicleListBloc>(
          create: (_) => VehicleListBloc(repository: dependencies.vehicleRepository),
        ),
        if (initialSchoolId == null)
          BlocProvider<SchoolScopeBloc>(
            create: (_) => SchoolScopeBloc(
              repository: dependencies.organizationOnboardingRepository,
            )..add(SchoolScopeStarted(organizationScopeId: initialOrganizationId)),
          ),
      ],
      child: VehicleListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
