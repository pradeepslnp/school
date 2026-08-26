import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../guardians/bloc/student_guardians_bloc.dart';
import '../../guardians/bloc/student_guardians_event.dart';
import '../domain/student_models.dart';
import 'student_detail_screen.dart';

/// Composes the student record (A-11) — matching `StudentListRoute`'s split: the route owns the
/// wiring, the screen owns none of it.
///
/// Pushed as an ordinary page over the register rather than being a shell destination: it is
/// about one specific student, so it takes a [Student] rather than being reachable from the nav
/// rail. The trade-off is that its browser URL stays the register's — acceptable for a detail
/// view, and revisited if deep-linking to a single student is ever needed.
class StudentDetailRoute extends StatelessWidget {
  const StudentDetailRoute({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<StudentGuardiansBloc>(
      create: (_) => StudentGuardiansBloc(repository: dependencies.guardianRepository)
        ..add(StudentGuardiansRequested(studentId: student.id)),
      child: StudentDetailScreen(student: student),
    );
  }
}
