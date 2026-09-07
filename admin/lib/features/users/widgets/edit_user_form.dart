import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../domain/user_models.dart';

/// Edits an administrative account's name and locale (`PERM-USER-EDIT`, screen A-43).
///
/// Deliberately cannot change email, phone, role, or scope: `UpdateAdministrativeUserCommand`
/// on the backend only ever touches the profile fields below — reassigning a role or moving
/// someone to a different school is a bigger decision than this dialog is meant to make easy,
/// and neither has a use case implemented yet (flagged as future work, not hidden).
class EditUserForm extends StatefulWidget {
  const EditUserForm({
    super.key,
    required this.user,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final AdminUser user;

  final void Function({
    required String firstName,
    required String lastName,
    required String preferredLocale,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<EditUserForm> createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  late final TextEditingController _firstName =
      TextEditingController(text: widget.user.firstName);
  late final TextEditingController _lastName =
      TextEditingController(text: widget.user.lastName);
  late final TextEditingController _locale =
      TextEditingController(text: widget.user.preferredLocale);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _locale.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      firstName: _firstName.text,
      lastName: _lastName.text,
      preferredLocale: _locale.text.trim().isEmpty ? 'en' : _locale.text.trim(),
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
          context.l10n.editStaffTitle(widget.user.displayName),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          context.l10n.userListRowSubtitle(
            widget.user.email,
            roleDisplayName(context.l10n, widget.user.primaryRoleCode),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('edit_user_form_first_name_field'),
          controller: _firstName,
          autofocus: true,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.firstNameLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('edit_user_form_last_name_field'),
          controller: _lastName,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.lastNameLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('edit_user_form_locale_field'),
          controller: _locale,
          enabled: !widget.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.l10n.editUserLocaleLabel,
            hintText: context.l10n.editUserLocaleHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('edit_user_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('edit_user_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(semanticsLabel: context.l10n.commonSavingSpinnerLabel)
                    : Text(context.l10n.commonSaveButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
