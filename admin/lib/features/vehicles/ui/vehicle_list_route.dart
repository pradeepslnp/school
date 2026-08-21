import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/vehicle_list_bloc.dart';
import 'vehicle_list_screen.dart';

/// Composes the Vehicles feature (A-20) — matching `StaffListRoute`'s split: the route owns
/// the wiring, the screen owns none of it.
class VehicleListRoute extends StatelessWidget {
  const VehicleListRoute({super.key, this.initialSchoolId});

  final String? initialSchoolId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<VehicleListBloc>(
      create: (_) => VehicleListBloc(repository: dependencies.vehicleRepository),
      child: VehicleListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
