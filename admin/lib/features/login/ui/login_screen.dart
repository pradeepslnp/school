import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/credentials_form.dart';
import '../widgets/login_error_text.dart';
import '../widgets/session_ended_notice.dart';
import '../widgets/sign_in_scaffold.dart';

/// The console's sign-in screen.
///
/// Holds no state and makes no decisions. It renders [LoginState] and dispatches what the
/// operator did; the bloc decides everything else (CODING_STANDARDS_FLUTTER.md §Layering).
///
/// There is no navigation here. Signing in changes the session, the router listens to the
/// session, and this screen is replaced — so "where to go next" is answered in exactly one
/// place rather than by every screen that can end a session.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SignInScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.signedOutReason != null)
                SessionEndedNotice(reason: state.signedOutReason!),
              CredentialsForm(
                isSubmitting: state.isSubmitting,
                onSubmit: ({
                  required String email,
                  required String password,
                }) =>
                    context.read<LoginBloc>().add(
                          LoginSubmitted(email: email, password: password),
                        ),
              ),
              if (state.error != null)
                LoginErrorText(
                  code: state.error!,
                  messageKey: state.errorMessageKey,
                ),
            ],
          ),
        );
      },
    );
  }
}
