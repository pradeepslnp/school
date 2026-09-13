import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../school_scope/bloc/school_scope_bloc.dart';
import '../../school_scope/bloc/school_scope_event.dart';
import '../bloc/student_list_bloc.dart';
import 'student_list_screen.dart';

/// Composes the student register (A-10) — matching `StaffListRoute`'s split: the route owns the
/// wiring, the screen owns none of it.
class StudentListRoute extends StatelessWidget {
  const StudentListRoute({super.key, this.initialSchoolId, this.initialOrganizationId});

  final String? initialSchoolId;

  /// The signed-in operator's own organization (`AuthenticatedUser.organizationScopeId`),
  /// passed through to `SchoolPickerField` only when [initialSchoolId] is null — an `ORG_ADMIN`
  /// has no single school to pre-fill but does have one organization, so the picker can go
  /// straight to its schools instead of asking which organization first (that step is for a
  /// `SUPER_ADMIN`, who has neither, alone).
  final String? initialOrganizationId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<StudentListBloc>(
          create: (_) => StudentListBloc(repository: dependencies.studentRepository),
        ),
        // Only created when the screen actually needs a picker — a school-scoped role never
        // pays for an organizations/schools fetch it has no use for.
        if (initialSchoolId == null)
          BlocProvider<SchoolScopeBloc>(
            create: (_) => SchoolScopeBloc(
              repository: dependencies.organizationOnboardingRepository,
              actingOrganization: dependencies.actingOrganization,
            )..add(SchoolScopeStarted(organizationScopeId: initialOrganizationId)),
          ),
      ],
      child: StudentListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
