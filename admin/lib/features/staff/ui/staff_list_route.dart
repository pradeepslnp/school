import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/staff_list_bloc.dart';
import 'staff_list_screen.dart';

/// Composes the Drivers feature (A-23) — matching `OrganizationListRoute`'s split: the route
/// owns the wiring, the screen owns none of it.
class StaffListRoute extends StatelessWidget {
  const StaffListRoute({super.key, this.initialSchoolId});

  final String? initialSchoolId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<StaffListBloc>(
      create: (_) => StaffListBloc(repository: dependencies.staffRepository),
      child: StaffListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
