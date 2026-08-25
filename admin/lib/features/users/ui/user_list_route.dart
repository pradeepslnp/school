import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/user_list_bloc.dart';
import '../bloc/user_list_event.dart';
import 'user_list_screen.dart';

/// Composes the Users feature (A-43) — matching `StaffListRoute`'s split: the route owns the
/// wiring, the screen owns none of it.
class UserListRoute extends StatelessWidget {
  const UserListRoute({
    super.key,
    required this.actorRoles,
    this.initialOrganizationId,
    this.initialSchoolId,
  });

  /// The signed-in operator's own roles (`AuthenticatedUser.roles`) — filters the create
  /// dialog's role dropdown to what BR-IAM-006 lets this operator grant
  /// (`assignableRoleCodes`). Unlike every other route in this console, this screen's own
  /// dialog needs to know who is looking at it, not just which organization/school.
  final List<String> actorRoles;

  /// An `ORG_ADMIN`'s own organization — set means [UserListBloc] skips straight to that
  /// organization's users (`UserListStarted.organizationId`).
  final String? initialOrganizationId;

  /// A `SCHOOL_ADMIN`'s own school — set (and [initialOrganizationId] null) means the bloc
  /// resolves the owning organization first (`UserListStarted.schoolIdToResolve`). The same
  /// id also locks the create dialog's school selection (`UserListScreen.lockedSchoolId`):
  /// a `SCHOOL_ADMIN` only ever grants roles within their own school.
  final String? initialSchoolId;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<UserListBloc>(
      create: (_) => UserListBloc(
        userRepository: dependencies.userRepository,
        organizationRepository: dependencies.organizationOnboardingRepository,
      )..add(UserListStarted(
          organizationId: initialOrganizationId,
          schoolIdToResolve: initialOrganizationId == null ? initialSchoolId : null,
        )),
      child: UserListScreen(
        actorRoles: actorRoles,
        lockedSchoolId: initialOrganizationId == null ? initialSchoolId : null,
      ),
    );
  }
}
