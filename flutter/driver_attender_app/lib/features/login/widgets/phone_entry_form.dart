import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/l10n_extensions.dart';
import 'button_spinner.dart';

/// Mobile-number entry.
///
/// Owns its controller and nothing else. It renders what it is given and reports what the
/// driver did; whether the number is acceptable, whether a code was sent, and what a failure
/// means are all decided above it (ENGINEERING_PRINCIPLES.md §8).
///
/// No format mask and no country-code picker. Phone format is validated against the region
/// profile server-side (ADR-0007) — a mask hardcoded here would silently reject valid
/// numbers the moment the platform opened in a country whose numbering plan this build
/// predates.
class PhoneEntryForm extends StatefulWidget {
  const PhoneEntryForm({
    super.key,
    required this.onSubmit,
    this.initialValue = '',
    this.isSubmitting = false,
  });

  final ValueChanged<String> onSubmit;
  final String initialValue;
  final bool isSubmitting;

  @override
  State<PhoneEntryForm> createState() => _PhoneEntryFormState();
}

class _PhoneEntryFormState extends State<PhoneEntryForm> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

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
        Text(l10n.phoneEntryTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: DriverSpacing.sm),
        Text(
          l10n.phoneEntrySubtitle,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: DriverSpacing.lg),
        TextField(
          key: const Key('driver_login_phone_field'),
          controller: _controller,
          autofocus: true,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          onSubmitted: (_) => _submit(),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: l10n.phoneFieldLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.phone_outlined),
            // Comfortably past the 64 px floor: this is the first thing a driver touches at
            // the start of a shift, often in daylight glare (DRIVER_ATTENDANT_APP.md).
            constraints: const BoxConstraints(minHeight: kDriverTouchTarget),
          ),
        ),
        const SizedBox(height: DriverSpacing.lg),
        FilledButton(
          key: const Key('driver_login_request_otp_button'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const ButtonSpinner()
              : Text(l10n.sendCodeButton),
        ),
      ],
    );
  }
}
