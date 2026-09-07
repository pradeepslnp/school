import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import 'onboarding_button_spinner.dart';

/// Step 1: the organization's own details (TEN-001).
///
/// Owns its controllers and nothing else — validity and uniqueness are the server's decision
/// (BR-TEN-007), matching `CredentialsForm`'s split.
class CreateOrganizationForm extends StatefulWidget {
  const CreateOrganizationForm({
    super.key,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final void Function({
    required String code,
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) onSubmit;

  final bool isSubmitting;

  @override
  State<CreateOrganizationForm> createState() => _CreateOrganizationFormState();
}

class _CreateOrganizationFormState extends State<CreateOrganizationForm> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _regionProfileCode = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _regionProfileCode.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      code: _code.text,
      name: _name.text,
      regionProfileCode: _regionProfileCode.text,
      contactEmail: _contactEmail.text,
      contactPhone: _contactPhone.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.createOrgStepTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          context.l10n.createOrgIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('org_onboarding_code_field'),
          controller: _code,
          autofocus: true,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: context.l10n.createOrgCodeLabel,
            hintText: context.l10n.createOrgCodeHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.createOrgNameLabel,
            hintText: context.l10n.createOrgNameHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_region_field'),
          controller: _regionProfileCode,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: context.l10n.createOrgRegionLabel,
            hintText: context.l10n.createOrgRegionHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_contact_email_field'),
          controller: _contactEmail,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.l10n.createOrgContactEmailLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_contact_phone_field'),
          controller: _contactPhone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.l10n.createOrgContactPhoneLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('org_onboarding_create_org_button'),
          // Stays enabled on empty fields — the bloc answers with a specific message rather
          // than a disabled control explaining nothing (ACCESSIBILITY.md §Operable).
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? OnboardingButtonSpinner(semanticsLabel: context.l10n.createOrgCreatingSpinnerLabel)
              : Text(context.l10n.createOrgSubmitButton),
        ),
      ],
    );
  }
}
