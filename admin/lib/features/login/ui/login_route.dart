import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../core/session/session_manager.dart';
import '../bloc/login_bloc.dart';
import 'login_screen.dart';

/// Composes the sign-in feature.
///
/// The route owns the wiring — repository and session manager in, bloc out — and the screen
/// owns none of it (PROJECT_STRUCTURE.md §Flutter Layout). That split is what lets a widget
/// test pump [LoginScreen] under a fake bloc without constructing an HTTP client.
class LoginRoute extends StatelessWidget {
  const LoginRoute({super.key, this.signedOutReason, this.onForgotPassword});

  /// Why the previous session ended, when it ended on its own. Passed in by the router,
  /// which is the only thing that knows.
  final SignOutReason? signedOutReason;

  /// Opens the forgot-password page (ADR-0012). Supplied by the router.
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<LoginBloc>(
      create: (_) => LoginBloc(
        repository: dependencies.loginRepository,
        sessionManager: dependencies.sessionManager,
        signedOutReason: signedOutReason,
      ),
      child: LoginScreen(onForgotPassword: onForgotPassword),
    );
  }
}
