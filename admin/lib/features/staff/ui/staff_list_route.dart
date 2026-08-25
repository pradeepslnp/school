import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../school_scope/bloc/school_scope_bloc.dart';
import '../../school_scope/bloc/school_scope_event.dart';
import '../bloc/staff_list_bloc.dart';
import 'staff_list_screen.dart';

/// Composes the Drivers feature (A-23) — matching `OrganizationListRoute`'s split: the route
/// owns the wiring, the screen owns none of it.
class StaffListRoute extends StatelessWidget {
  const StaffListRoute({super.key, this.initialSchoolId, this.initialOrganizationId});

  final String? initialSchoolId;

  /// See `StudentListRoute.initialOrganizationId` — same reasoning, same source.
  final String? initialOrganizationId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<StaffListBloc>(
          create: (_) => StaffListBloc(repository: dependencies.staffRepository),
        ),
        if (initialSchoolId == null)
          BlocProvider<SchoolScopeBloc>(
            create: (_) => SchoolScopeBloc(
              repository: dependencies.organizationOnboardingRepository,
            )..add(SchoolScopeStarted(organizationScopeId: initialOrganizationId)),
          ),
      ],
      child: StaffListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
