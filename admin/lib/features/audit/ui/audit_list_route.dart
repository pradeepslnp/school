import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/audit_list_bloc.dart';
import '../bloc/audit_list_event.dart';
import 'audit_list_screen.dart';

/// Composes the audit trail (A-54) — matching `UserListRoute`'s split: the route owns the wiring,
/// the screen owns none of it.
class AuditListRoute extends StatelessWidget {
  const AuditListRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<AuditListBloc>(
      create: (_) => AuditListBloc(repository: dependencies.auditRepository)
        ..add(const AuditRequested()),
      child: const AuditListScreen(),
    );
  }
}
