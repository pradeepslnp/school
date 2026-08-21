import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../core/session/session_manager.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_state.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

/// Composition point for sign-in: builds the bloc from the app's dependencies and chooses
/// which step is on screen.
///
/// The screens themselves take no constructor arguments and know nothing about how the bloc
/// was built, which is what lets either of them be rendered in a test with a fake bloc and
/// no HTTP, keychain, or database (PROJECT_STRUCTURE.md: `ui/` composes the feature's
/// dependencies).
class LoginRoute extends StatelessWidget {
  const LoginRoute({super.key, this.signedOutReason});

  /// Why the previous session ended, if it ended without the driver asking.
  final SignOutReason? signedOutReason;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<LoginBloc>(
      create: (_) => LoginBloc(
        repository: dependencies.loginRepository,
        sessionManager: dependencies.sessionManager,
        signedOutReason: signedOutReason,
      ),
      child: BlocBuilder<LoginBloc, LoginState>(
        // Only the step decides which screen is shown, so the whole subtree does not rebuild
        // on every keystroke-driven state change.
        buildWhen: (previous, current) => previous.step != current.step,
        builder: (context, state) => switch (state.step) {
          LoginStep.enteringPhone => const LoginScreen(),
          LoginStep.enteringCode => const OtpScreen(),
        },
      ),
    );
  }
}
