import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import 'button_spinner.dart';

/// Passwordless sign-in: request a one-time code by email, then enter it (IAM-001, ADR-0012).
///
/// Two steps in one widget, chosen by [codeSent], because they are one task — and because the
/// address entered in step one is what step two's code is checked against, so splitting them
/// across screens would mean carrying it somewhere.
///
/// Owns its controllers and nothing else: whether the address exists, whether the code is right,
/// and what a failure means are all decided above it (ENGINEERING_PRINCIPLES.md §8). The code
/// never leaves this widget except on [onSubmitCode] — it is a credential, and is not held in
/// bloc state for the same reason the password is not.
class EmailCodeForm extends StatefulWidget {
  const EmailCodeForm({
    super.key,
    required this.codeSent,
    required this.codeEmail,
    required this.isSubmitting,
    required this.onRequestCode,
    required this.onSubmitCode,
    required this.onUseDifferentEmail,
  });

  /// False shows the address step; true shows the code step.
  final bool codeSent;

  /// The address the code was sent to, shown on the code step so the operator can check it.
  final String codeEmail;

  final bool isSubmitting;
  final void Function(String email) onRequestCode;
  final void Function(String otp) onSubmitCode;
  final VoidCallback onUseDifferentEmail;

  @override
  State<EmailCodeForm> createState() => _EmailCodeFormState();
}

class _EmailCodeFormState extends State<EmailCodeForm> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _otp = TextEditingController();

  @override
  void didUpdateWidget(EmailCodeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Returning to the address step clears a code typed against the previous address, so it
    // cannot be submitted against a different account.
    if (oldWidget.codeSent && !widget.codeSent) {
      _otp.clear();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _requestCode() {
    if (widget.isSubmitting) return;
    widget.onRequestCode(_email.text);
  }

  void _submitCode() {
    if (widget.isSubmitting) return;
    widget.onSubmitCode(_otp.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.codeSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We will email you a 6-digit code to sign in. No password needed.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AdminSpacing.lg),
          TextField(
            key: const Key('admin_login_code_email_field'),
            controller: _email,
            autofocus: true,
            enabled: !widget.isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) => _requestCode(),
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
              constraints: BoxConstraints(minHeight: kAdminTouchTarget),
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
          FilledButton(
            key: const Key('admin_login_request_code_button'),
            onPressed: widget.isSubmitting ? null : _requestCode,
            child: widget.isSubmitting
                ? const ButtonSpinner(semanticsLabel: 'Sending code')
                : const Text('Email me a code'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'If an account exists for ${widget.codeEmail}, a 6-digit code is on its way. '
          'It is valid for 10 minutes.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('admin_login_code_field'),
          controller: _otp,
          autofocus: true,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _submitCode(),
          decoration: const InputDecoration(
            labelText: '6-digit code',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('admin_login_verify_code_button'),
          onPressed: widget.isSubmitting ? null : _submitCode,
          child: widget.isSubmitting
              ? const ButtonSpinner(semanticsLabel: 'Signing in')
              : const Text('Sign in'),
        ),
        TextButton(
          key: const Key('admin_login_change_email_button'),
          onPressed: widget.isSubmitting ? null : widget.onUseDifferentEmail,
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
