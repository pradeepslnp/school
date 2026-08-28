import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/set_password_bloc.dart';
import 'set_password_screen.dart';

/// Composes the accept-invitation page (ADR-0012, IAM-009), reached from an emailed link at
/// `/accept-invitation?token=…`. Public — the invitee has a link, not a session.
///
/// The route owns the wiring; [SetPasswordScreen] owns none of it. [onDone] is supplied by the
/// router so "where to go after activating" is answered in one place, matching `LoginScreen`.
class AcceptInvitationRoute extends StatelessWidget {
  const AcceptInvitationRoute({super.key, required this.token, required this.onDone});

  final String token;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<SetPasswordBloc>(
      create: (_) => SetPasswordBloc(
        repository: dependencies.authRecoveryRepository,
        token: token,
        mode: PasswordSetMode.acceptInvitation,
      ),
      child: SetPasswordScreen(
        title: 'Set your password',
        intro: 'Choose a password to activate your account and sign in.',
        submitLabel: 'Activate account',
        doneTitle: 'Account activated',
        doneBody: 'You can now sign in with your email address and new password.',
        onDone: onDone,
      ),
    );
  }
}
