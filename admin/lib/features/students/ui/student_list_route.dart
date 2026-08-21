import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/student_list_bloc.dart';
import 'student_list_screen.dart';

/// Composes the student register (A-10) — matching `StaffListRoute`'s split: the route owns the
/// wiring, the screen owns none of it.
class StudentListRoute extends StatelessWidget {
  const StudentListRoute({super.key, this.initialSchoolId});

  final String? initialSchoolId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<StudentListBloc>(
      create: (_) => StudentListBloc(repository: dependencies.studentRepository),
      child: StudentListScreen(initialSchoolId: initialSchoolId),
    );
  }
}
