import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'button_spinner.dart';

/// Email and password entry.
///
/// Owns its controllers and nothing else. It renders what it is given and reports what the
/// operator did; whether the credentials are acceptable and what a failure means are decided
/// above it (ENGINEERING_PRINCIPLES.md §8).
///
/// The password never leaves this widget except on [onSubmit] — it is not held in bloc
/// state, so there is no retained object for an observer or an error reporter to print.
class CredentialsForm extends StatefulWidget {
  const CredentialsForm({
    super.key,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final void Function({required String email, required String password}) onSubmit;

  final bool isSubmitting;

  @override
  State<CredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends State<CredentialsForm> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _passwordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sign in', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'Guardian administration console',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('admin_login_email_field'),
          controller: _email,
          autofocus: true,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          // Enter moves to the password rather than submitting a half-filled form.
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          decoration: const InputDecoration(
            labelText: 'Email address',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('admin_login_password_field'),
          controller: _password,
          focusNode: _passwordFocus,
          enabled: !widget.isSubmitting,
          obscureText: !_passwordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
            // A reveal control, because a password typed wrongly three times locks the
            // account (BR-IAM-011) — and the operator has no way to see why.
            suffixIcon: IconButton(
              key: const Key('admin_login_password_visibility'),
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              // Describes the action, not the current state: a screen reader user needs to
              // know what activating it will do.
              tooltip: _passwordVisible ? 'Hide password' : 'Show password',
              onPressed: widget.isSubmitting
                  ? null
                  : () => setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('admin_login_submit_button'),
          // Stays enabled on empty fields. A disabled control is unreachable by keyboard and
          // explains nothing; the bloc answers with a specific message instead
          // (ACCESSIBILITY.md §Operable).
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const ButtonSpinner(semanticsLabel: 'Signing in')
              : const Text('Sign in'),
        ),
      ],
    );
  }
}
