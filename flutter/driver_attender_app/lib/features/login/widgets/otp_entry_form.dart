import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/l10n_extensions.dart';
import 'button_spinner.dart';

/// One-time code entry.
///
/// Renders state and reports what the driver did. Whether the code is right, whether a
/// resend is allowed, and what any failure means are decided above it.
class OtpEntryForm extends StatefulWidget {
  const OtpEntryForm({
    super.key,
    required this.phone,
    required this.onSubmit,
    required this.onResend,
    required this.onChangeNumber,
    this.isSubmitting = false,
    this.codeResent = false,
  });

  /// Shown back to the driver so a mistyped number is caught here rather than after two
  /// minutes of waiting for a code that went somewhere else.
  final String phone;

  final ValueChanged<String> onSubmit;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;
  final bool isSubmitting;
  final bool codeResent;

  @override
  State<OtpEntryForm> createState() => _OtpEntryFormState();
}

class _OtpEntryFormState extends State<OtpEntryForm> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.otpEntryTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: DriverSpacing.sm),
        Text(
          l10n.otpEntrySubtitle(widget.phone),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: DriverSpacing.lg),
        TextField(
          key: const Key('driver_login_otp_field'),
          controller: _controller,
          autofocus: true,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          // Lets the platform fill the code from the SMS, which is the difference between
          // one action and switching apps to read it.
          autofillHints: const [AutofillHints.oneTimeCode],
          onSubmitted: (_) => _submit(),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: l10n.otpFieldLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.sms_outlined),
            constraints: const BoxConstraints(minHeight: kDriverTouchTarget),
          ),
        ),
        if (widget.codeResent) ...[
          const SizedBox(height: DriverSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.otpResentNotice,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.status.safe,
              ),
            ),
          ),
        ],
        const SizedBox(height: DriverSpacing.lg),
        FilledButton(
          key: const Key('driver_login_verify_button'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const ButtonSpinner()
              : Text(l10n.verifyButton),
        ),
        const SizedBox(height: DriverSpacing.sm),
        // Both recovery paths are on screen rather than behind a menu. A driver who mistyped
        // a digit or never received the SMS is stuck at the depot gate until one of them is
        // within reach.
        Row(
          children: [
            Expanded(
              child: TextButton(
                key: const Key('driver_login_change_number_button'),
                onPressed:
                    widget.isSubmitting ? null : widget.onChangeNumber,
                child: Text(l10n.changeNumberButton),
              ),
            ),
            Expanded(
              child: TextButton(
                key: const Key('driver_login_resend_button'),
                onPressed: widget.isSubmitting ? null : widget.onResend,
                child: Text(l10n.resendCodeButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
