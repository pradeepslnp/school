import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../custody_restrictions/bloc/student_custody_bloc.dart';
import '../../custody_restrictions/bloc/student_custody_event.dart';
import '../../guardians/bloc/student_guardians_bloc.dart';
import '../../guardians/bloc/student_guardians_event.dart';
import '../../route_assignments/bloc/student_assignments_bloc.dart';
import '../../route_assignments/bloc/student_assignments_event.dart';
import '../domain/student_models.dart';
import 'student_detail_screen.dart';

/// Composes the student record (A-11) — matching `StudentListRoute`'s split: the route owns the
/// wiring, the screen owns none of it.
///
/// Two blocs, because the screen has two independent panels — parents and pickup/drop — each with
/// its own load and its own submit state. Both are seeded on entry so the record is populated by
/// the time the operator reads it.
///
/// Pushed as an ordinary page over the register rather than being a shell destination: it is about
/// one specific student, so it takes a [Student] rather than being reachable from the nav rail. The
/// trade-off is that its browser URL stays the register's — acceptable for a detail view, and
/// revisited if deep-linking to a single student is ever needed.
class StudentDetailRoute extends StatelessWidget {
  const StudentDetailRoute({super.key, required this.student});

  final Student student;

  /// Holders of `PERM-CUSTODY-RESTRICTION-MANAGE` (PERMISSION_MATRIX.md) — the same three roles
  /// that hold the other write permissions on this screen.
  static const _custodyRoles = {'SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN'};

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);
    final roles = dependencies.sessionManager.currentUser?.roles ?? const <String>[];
    final canManageCustody = roles.any(_custodyRoles.contains);

    return MultiBlocProvider(
      providers: [
        BlocProvider<StudentGuardiansBloc>(
          create: (_) => StudentGuardiansBloc(repository: dependencies.guardianRepository)
            ..add(StudentGuardiansRequested(studentId: student.id)),
        ),
        BlocProvider<StudentAssignmentsBloc>(
          create: (_) =>
              StudentAssignmentsBloc(repository: dependencies.routeAssignmentRepository)
                ..add(StudentAssignmentsRequested(studentId: student.id)),
        ),
        // Only for roles that can reach the endpoint — a PRINCIPAL who may view the record
        // never triggers a custody-restriction fetch the server would refuse (BR-GRD-008 🔴).
        if (canManageCustody)
          BlocProvider<StudentCustodyBloc>(
            create: (_) =>
                StudentCustodyBloc(repository: dependencies.custodyRestrictionRepository)
                  ..add(StudentCustodyRequested(studentId: student.id)),
          ),
      ],
      child: StudentDetailScreen(
        student: student,
        showCustodyPanel: canManageCustody,
      ),
    );
  }
}
