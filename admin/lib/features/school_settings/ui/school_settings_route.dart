import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/school_settings_bloc.dart';
import 'school_settings_screen.dart';

/// Composes the School feature (A-41) — matching `StaffListRoute`'s split: the route owns the
/// wiring, the screen owns none of it.
class SchoolSettingsRoute extends StatelessWidget {
  const SchoolSettingsRoute({super.key, required this.schoolId});

  final String schoolId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<SchoolSettingsBloc>(
      create: (_) => SchoolSettingsBloc(
        repository: dependencies.organizationOnboardingRepository,
      ),
      child: SchoolSettingsScreen(schoolId: schoolId),
    );
  }
}
