import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependencies.dart';
import '../bloc/student_import_bloc.dart';
import '../data_provider/student_import_file_gateway.dart';
import 'student_import_screen.dart';

/// Composes the bulk student import screen (A-12) — the route owns the wiring, the screen owns
/// none of it, matching `StudentListRoute`.
///
/// Pushed as an ordinary page over the register rather than being a nav-rail destination: it is
/// an action taken from the register for one school, not a place. On pop it returns `true` when
/// at least one student was enrolled, so the register can refresh.
class StudentImportRoute extends StatelessWidget {
  const StudentImportRoute({super.key, required this.schoolId});

  final String schoolId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<StudentImportBloc>(
      create: (_) =>
          StudentImportBloc(repository: dependencies.studentImportRepository),
      child: StudentImportScreen(
        schoolId: schoolId,
        gateway: const StudentImportFileGateway(),
      ),
    );
  }
}
