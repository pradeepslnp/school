import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// The minimum password length, mirroring the server's {@code PasswordPolicy} (BR-IAM-013). An
/// affordance only — the server is what enforces it, and it also screens common passwords the
/// client does not (ADR-0012).
const int kMinPasswordLength = 12;

/// Password + confirmation entry, shared by the accept-invitation and reset-password screens.
///
/// Owns only field state and client-side checks (length, and that the two entries match); it makes
/// no network decisions and holds no token. Submitting hands the chosen password up via [onSubmit];
/// everything past that is the bloc's job.
class NewPasswordForm extends StatefulWidget {
  const NewPasswordForm({
    super.key,
    required this.submitLabel,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String submitLabel;
  final bool isSubmitting;
  final void Function(String password) onSubmit;

  @override
  State<NewPasswordForm> createState() => _NewPasswordFormState();
}

class _NewPasswordFormState extends State<NewPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('new_password_field'),
            controller: _password,
            obscureText: _obscure,
            enabled: !widget.isSubmitting,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'New password',
              helperText: 'At least $kMinPasswordLength characters.',
              border: const OutlineInputBorder(),
              constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
              suffixIcon: IconButton(
                key: const Key('new_password_visibility'),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (value) {
              final text = value ?? '';
              if (text.length < kMinPasswordLength) {
                return 'Use at least $kMinPasswordLength characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            key: const Key('confirm_password_field'),
            controller: _confirm,
            obscureText: _obscure,
            enabled: !widget.isSubmitting,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              border: OutlineInputBorder(),
              constraints: BoxConstraints(minHeight: kAdminTouchTarget),
            ),
            validator: (value) {
              if ((value ?? '') != _password.text) {
                return 'The two passwords do not match.';
              }
              return null;
            },
          ),
          const SizedBox(height: AdminSpacing.lg),
          FilledButton(
            key: const Key('new_password_submit'),
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
