import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/credentials_form.dart';
import '../widgets/email_code_form.dart';
import '../widgets/login_error_text.dart';
import '../widgets/session_ended_notice.dart';
import '../widgets/sign_in_scaffold.dart';

/// The console's sign-in screen.
///
/// Holds no state and makes no decisions. It renders [LoginState] and dispatches what the
/// operator did; the bloc decides everything else (CODING_STANDARDS_FLUTTER.md §Layering).
///
/// Two ways in, both issuing the same session (IAM-001, ADR-0012): email + password, or a
/// one-time code emailed on request. Neither replaces the other — an organisation that prefers
/// passwords keeps them, and one that would rather not manage passwords never sets one.
///
/// There is no navigation here. Signing in changes the session, the router listens to the
/// session, and this screen is replaced — so "where to go next" is answered in exactly one
/// place rather than by every screen that can end a session.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.onForgotPassword});

  /// Opens the forgot-password page (ADR-0012), supplied by the router. Null hides the link.
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SignInScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.signedOutReason != null)
                SessionEndedNotice(reason: state.signedOutReason!),
              Text('Sign in', style: theme.textTheme.titleLarge),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                'Guardian administration console',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AdminSpacing.lg),
              SegmentedButton<bool>(
                key: const Key('admin_login_method_toggle'),
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Password'),
                    icon: Icon(Icons.password_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Email code'),
                    icon: Icon(Icons.mail_outline),
                  ),
                ],
                selected: {state.useEmailCode},
                onSelectionChanged: state.isSubmitting
                    ? null
                    : (selection) => context
                        .read<LoginBloc>()
                        .add(LoginMethodChanged(selection.first)),
              ),
              const SizedBox(height: AdminSpacing.lg),
              if (state.useEmailCode)
                EmailCodeForm(
                  codeSent: state.codeSent,
                  codeEmail: state.codeEmail,
                  isSubmitting: state.isSubmitting,
                  onRequestCode: (email) =>
                      context.read<LoginBloc>().add(EmailOtpRequested(email)),
                  onSubmitCode: (otp) =>
                      context.read<LoginBloc>().add(EmailOtpSubmitted(otp)),
                  onUseDifferentEmail: () =>
                      context.read<LoginBloc>().add(const EmailOtpRestarted()),
                )
              else
                CredentialsForm(
                  isSubmitting: state.isSubmitting,
                  onForgotPassword: onForgotPassword,
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
