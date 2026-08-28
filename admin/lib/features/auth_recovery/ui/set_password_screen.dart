import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../login/widgets/sign_in_scaffold.dart';
import '../bloc/set_password_bloc.dart';
import '../widgets/new_password_form.dart';

/// The accept-invitation and reset-password screen (ADR-0012). Both flows land here; the copy is
/// passed in so the one screen serves either.
///
/// Renders [SetPasswordState] and dispatches what the person did — no decisions, no navigation of
/// its own. When the password is set it shows a done panel whose only action calls [onDone], which
/// the router wires to return to sign-in.
class SetPasswordScreen extends StatelessWidget {
  const SetPasswordScreen({
    super.key,
    required this.title,
    required this.intro,
    required this.submitLabel,
    required this.doneTitle,
    required this.doneBody,
    required this.onDone,
  });

  final String title;
  final String intro;
  final String submitLabel;
  final String doneTitle;
  final String doneBody;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SetPasswordBloc, SetPasswordState>(
      builder: (context, state) {
        if (state.isDone) {
          return SignInScaffold(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: context.status.safe),
                    const SizedBox(width: AdminSpacing.sm),
                    Expanded(child: Text(doneTitle, style: theme.textTheme.titleLarge)),
                  ],
                ),
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  doneBody,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AdminSpacing.lg),
                FilledButton(
                  key: const Key('set_password_done_button'),
                  onPressed: onDone,
                  child: const Text('Go to sign in'),
                ),
              ],
            ),
          );
        }

        return SignInScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                intro,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AdminSpacing.lg),
              NewPasswordForm(
                submitLabel: submitLabel,
                isSubmitting: state.isSubmitting,
                onSubmit: (password) =>
                    context.read<SetPasswordBloc>().add(SetPasswordSubmitted(password)),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AdminSpacing.md),
                  child: Text(
                    _errorText(state.error!),
                    key: const Key('set_password_error'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: context.status.critical),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _errorText(ErrorCode code) {
    return switch (code) {
      ErrorCode.authLinkExpired =>
        'This link has expired. Ask an administrator to send you a new one.',
      ErrorCode.authLinkAlreadyUsed =>
        'This link has already been used. If you have set your password, just sign in.',
      ErrorCode.authLinkInvalid =>
        'This link is not valid. Check you opened the most recent email, or ask for a new link.',
      ErrorCode.passwordTooWeak =>
        'That password is too weak. Use at least $kMinPasswordLength characters and avoid common passwords.',
      ErrorCode.dependencyUnavailable =>
        'We could not reach the server. Check your connection and try again.',
      _ => 'That could not be completed right now. Please try again.',
    };
  }
}
