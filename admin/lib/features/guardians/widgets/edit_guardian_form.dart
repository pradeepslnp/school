import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../domain/guardian_models.dart';

/// Corrects a parent's name, phone, or email from their card on the student record (A-11,
/// GRD-001). ADMIN_WEB.md §A-13, "Correcting a parent's details".
///
/// The phone field says, before saving, that a new number moves the parent's app sign-in and
/// signs the old number out (BR-IAM-014): the one consequence here that reaches someone other
/// than the operator. Rights are not edited here — they belong to the link with this child, not
/// to the parent, and are a separate control.
class EditGuardianForm extends StatefulWidget {
  const EditGuardianForm({
    super.key,
    required this.guardian,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final StudentGuardian guardian;

  final void Function({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<EditGuardianForm> createState() => _EditGuardianFormState();
}

class _EditGuardianFormState extends State<EditGuardianForm> {
  late final _firstName = TextEditingController(text: widget.guardian.firstName);
  late final _lastName = TextEditingController(text: widget.guardian.lastName);
  late final _phone = TextEditingController(text: widget.guardian.phone);
  late final _email = TextEditingController(text: widget.guardian.email ?? '');

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      firstName: _firstName.text,
      lastName: _lastName.text,
      phone: _phone.text,
      email: _email.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.editGuardianTitle(widget.guardian.displayName),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('guardian_edit_first_name_field'),
          controller: _firstName,
          autofocus: true,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.addGuardianFirstNameLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_edit_last_name_field'),
          controller: _lastName,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.addGuardianLastNameLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_edit_phone_field'),
          controller: _phone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: context.l10n.addGuardianPhoneLabel,
            helperText: context.l10n.editGuardianPhoneHelper,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_edit_email_field'),
          controller: _email,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.l10n.addGuardianEmailLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('guardian_edit_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('guardian_edit_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(semanticsLabel: context.l10n.commonSavingSpinnerLabel)
                    : Text(context.l10n.commonSaveChangesButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
