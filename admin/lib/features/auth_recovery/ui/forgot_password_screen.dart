import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../login/widgets/sign_in_scaffold.dart';
import '../bloc/forgot_password_bloc.dart';

/// The forgot-password screen (ADR-0012, IAM-010): enter an email, get a reset link.
///
/// The confirmation is deliberately generic — "if that account exists, we've sent a link" — so the
/// screen never reveals whether an address has an account (OWASP anti-enumeration). [onBack]
/// returns to sign-in and is supplied by the router.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, bool isSubmitting) {
    if (isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ForgotPasswordBloc>().add(ForgotPasswordSubmitted(_email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      builder: (context, state) {
        if (state.isSent) {
          return SignInScaffold(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, color: context.status.safe),
                    const SizedBox(width: AdminSpacing.sm),
                    Expanded(child: Text('Check your email', style: theme.textTheme.titleLarge)),
                  ],
                ),
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  'If an account exists for that address, a reset link is on its way. '
                  'The link is valid for 60 minutes.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AdminSpacing.lg),
                FilledButton(
                  key: const Key('forgot_password_back_button'),
                  onPressed: widget.onBack,
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          );
        }

        return SignInScaffold(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reset your password', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  'Enter your email and we will send you a link to set a new password.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AdminSpacing.lg),
                TextFormField(
                  key: const Key('forgot_password_email_field'),
                  controller: _email,
                  enabled: !state.isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(context, state.isSubmitting),
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    border: OutlineInputBorder(),
                    constraints: BoxConstraints(minHeight: kAdminTouchTarget),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty || !text.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AdminSpacing.lg),
                FilledButton(
                  key: const Key('forgot_password_submit'),
                  onPressed:
                      state.isSubmitting ? null : () => _submit(context, state.isSubmitting),
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send reset link'),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AdminSpacing.md),
                    child: Text(
                      'We could not reach the server. Check your connection and try again.',
                      key: const Key('forgot_password_error'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: context.status.critical),
                    ),
                  ),
                const SizedBox(height: AdminSpacing.sm),
                TextButton(
                  key: const Key('forgot_password_back_link'),
                  onPressed: widget.onBack,
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
