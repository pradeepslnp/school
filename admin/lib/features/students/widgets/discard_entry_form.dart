import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';

/// Confirms permanently deleting a record entered by mistake — a student (A-10, STU-008) or a
/// driver/attendant (A-23, STF-007). ADMIN_WEB.md §Discarding a Mistaken Entry, ADR-0019.
///
/// Built here, where it was first needed, and reused by the Drivers screen — the same way
/// `OnboardingButtonSpinner` is shared from the organizations feature. The caller supplies only
/// the [body], which says what this particular deletion removes.
///
/// Destructive actions always confirm (ACCESSIBILITY.md), and this one also needs a reason: the
/// record is gone afterwards, and the audit trail is all that will say why. So *Delete
/// permanently* stays disabled until a reason is typed, and is error-toned so it never reads as an
/// ordinary save.
///
/// Holds only the reason being typed; whether the deletion is allowed is the server's decision
/// (BR-STU-007, BR-STAFF-007) and comes back as [error].
class DiscardEntryForm extends StatefulWidget {
  const DiscardEntryForm({
    super.key,
    required this.body,
    required this.onConfirm,
    required this.onCancel,
    this.isSubmitting = false,
    this.error,
  });

  final String body;
  final ValueChanged<String> onConfirm;
  final VoidCallback onCancel;
  final bool isSubmitting;

  /// Why the last attempt was refused, rendered by the caller's own error widget. Shown only once
  /// this dialog has been submitted, so an earlier failure on the screen behind it never appears
  /// here as if the deletion had been refused.
  final Widget? error;

  @override
  State<DiscardEntryForm> createState() => _DiscardEntryFormState();
}

class _DiscardEntryFormState extends State<DiscardEntryForm> {
  /// `reason` is 1–500 characters server-side (ADR-0019).
  static const _reasonMaxLength = 500;

  final _reason = TextEditingController();
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _reason.addListener(_onReasonChanged);
  }

  @override
  void dispose() {
    _reason.removeListener(_onReasonChanged);
    _reason.dispose();
    super.dispose();
  }

  void _onReasonChanged() => setState(() {});

  bool get _canConfirm => !widget.isSubmitting && _reason.text.trim().isNotEmpty;

  void _confirm() {
    setState(() => _attempted = true);
    widget.onConfirm(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Icon as well as colour — colour is never the only signal (DESIGN_SYSTEM.md).
            Icon(Icons.delete_forever_outlined, color: scheme.error),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text(context.l10n.discardEntryTitle, style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        Text(widget.body, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('discard_entry_reason_field'),
          controller: _reason,
          autofocus: true,
          enabled: !widget.isSubmitting,
          minLines: 2,
          maxLines: 4,
          maxLength: _reasonMaxLength,
          decoration: InputDecoration(
            labelText: context.l10n.discardEntryReasonLabel,
            helperText: context.l10n.discardEntryReasonHelper,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_attempted && widget.error != null) widget.error!,
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('discard_entry_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('discard_entry_confirm_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: _canConfirm ? _confirm : null,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(
                        semanticsLabel: context.l10n.discardEntryDeletingSpinnerLabel,
                      )
                    : Text(context.l10n.discardEntryConfirmButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
