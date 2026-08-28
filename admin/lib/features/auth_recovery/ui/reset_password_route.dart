import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../bloc/set_password_bloc.dart';
import 'set_password_screen.dart';

/// Composes the reset-password page (ADR-0012, IAM-010), reached from an emailed link at
/// `/reset-password?token=…`. Public — the reset link is the credential.
class ResetPasswordRoute extends StatelessWidget {
  const ResetPasswordRoute({super.key, required this.token, required this.onDone});

  final String token;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<SetPasswordBloc>(
      create: (_) => SetPasswordBloc(
        repository: dependencies.authRecoveryRepository,
        token: token,
        mode: PasswordSetMode.resetPassword,
      ),
      child: SetPasswordScreen(
        title: 'Choose a new password',
        intro: 'Set a new password. This signs you out everywhere else.',
        submitLabel: 'Reset password',
        doneTitle: 'Password changed',
        doneBody: 'Your password has been reset. Sign in with your new password.',
        onDone: onDone,
      ),
    );
  }
}
