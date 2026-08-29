import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../login/widgets/sign_in_scaffold.dart';
import '../bloc/forgot_password_bloc.dart';
import '../widgets/new_password_form.dart';

/// The forgot-password / reset screen (ADR-0012, IAM-010), in two steps: enter an email to get a
/// code, then enter the code and a new password. [onBack] returns to sign-in and is supplied by the
/// router.
///
/// The confirmation that a code was sent is deliberately generic — the screen never reveals whether
/// an address has an account (OWASP anti-enumeration).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _requestCode(BuildContext context, bool isSubmitting) {
    if (isSubmitting) return;
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetBloc>().requestCode(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordResetBloc, PasswordResetState>(
      builder: (context, state) {
        return switch (state.phase) {
          PasswordResetPhase.enterEmail => _emailStep(context, state),
          PasswordResetPhase.enterCodeAndPassword => _codeStep(context, state),
          PasswordResetPhase.done => _doneStep(context),
        };
      },
    );
  }

  Widget _emailStep(BuildContext context, PasswordResetState state) {
    final theme = Theme.of(context);

    return SignInScaffold(
      child: Form(
        key: _emailKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reset your password', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              'Enter your email and we will send you a 6-digit code to reset your password.',
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
              onFieldSubmitted: (_) => _requestCode(context, state.isSubmitting),
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
                  state.isSubmitting ? null : () => _requestCode(context, state.isSubmitting),
              child: state.isSubmitting
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send code'),
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
  }

  Widget _codeStep(BuildContext context, PasswordResetState state) {
    final theme = Theme.of(context);

    return SignInScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter your code', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AdminSpacing.xs),
          Text(
            'If an account exists for ${state.email}, we’ve emailed a 6-digit code. '
            'It is valid for 10 minutes. Enter it and choose a new password.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AdminSpacing.lg),
          _ResetCodeAndPasswordForm(
            isSubmitting: state.isSubmitting,
            onSubmit: (otp, password) =>
                context.read<PasswordResetBloc>().submit(otp: otp, newPassword: password),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AdminSpacing.md),
              child: Text(
                _codeErrorText(state.error!),
                key: const Key('reset_error'),
                style: theme.textTheme.bodyMedium?.copyWith(color: context.status.critical),
              ),
            ),
          const SizedBox(height: AdminSpacing.sm),
          TextButton(
            key: const Key('reset_back_link'),
            onPressed: widget.onBack,
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }

  Widget _doneStep(BuildContext context) {
    final theme = Theme.of(context);

    return SignInScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: context.status.safe),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(child: Text('Password changed', style: theme.textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'Your password has been reset and you’ve been signed out everywhere else. '
            'Sign in with your new password.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AdminSpacing.lg),
          FilledButton(
            key: const Key('reset_done_button'),
            onPressed: widget.onBack,
            child: const Text('Go to sign in'),
          ),
        ],
      ),
    );
  }

  static String _codeErrorText(ErrorCode code) {
    return switch (code) {
      ErrorCode.authOtpExpired =>
        'That code has expired. Go back and request a new one.',
      ErrorCode.authOtpAlreadyUsed =>
        'That code has already been used. Request a new one if you still need to reset.',
      ErrorCode.authAccountLocked =>
        'Too many incorrect codes. Please wait 15 minutes and try again.',
      ErrorCode.authCredentialsInvalid =>
        'That code is not correct. Check the latest email and try again.',
      ErrorCode.passwordTooWeak =>
        'That password is too weak. Use at least $kMinPasswordLength characters and avoid common passwords.',
      ErrorCode.dependencyUnavailable =>
        'We could not reach the server. Check your connection and try again.',
      _ => 'That could not be completed right now. Please try again.',
    };
  }
}

/// Step two's form: the emailed code plus a new password and confirmation. Owns only field state
/// and client-side checks; the bloc does everything past [onSubmit].
class _ResetCodeAndPasswordForm extends StatefulWidget {
  const _ResetCodeAndPasswordForm({required this.isSubmitting, required this.onSubmit});

  final bool isSubmitting;
  final void Function(String otp, String password) onSubmit;

  @override
  State<_ResetCodeAndPasswordForm> createState() => _ResetCodeAndPasswordFormState();
}

class _ResetCodeAndPasswordFormState extends State<_ResetCodeAndPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_otp.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('reset_otp_field'),
            controller: _otp,
            enabled: !widget.isSubmitting,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: '6-digit code',
              border: OutlineInputBorder(),
              constraints: BoxConstraints(minHeight: kAdminTouchTarget),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.length != 6) return 'Enter the 6-digit code from your email.';
              return null;
            },
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            key: const Key('reset_new_password_field'),
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
                key: const Key('reset_password_visibility'),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (value) {
              if ((value ?? '').length < kMinPasswordLength) {
                return 'Use at least $kMinPasswordLength characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            key: const Key('reset_confirm_password_field'),
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
              if ((value ?? '') != _password.text) return 'The two passwords do not match.';
              return null;
            },
          ),
          const SizedBox(height: AdminSpacing.lg),
          FilledButton(
            key: const Key('reset_submit'),
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Reset password'),
          ),
        ],
      ),
    );
  }
}
