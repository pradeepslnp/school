import 'package:flutter/material.dart';

import '../../../app/theme.dart';
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
        Text('Step 1 of 2 — Organization details', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'This becomes a new tenant. The code is immutable once the organization has any '
          'schools or staff (BR-TEN-007).',
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
          decoration: const InputDecoration(
            labelText: 'Organization code',
            hintText: 'e.g. GREENWOOD',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Organization name',
            hintText: 'e.g. Greenwood Education Group',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_region_field'),
          controller: _regionProfileCode,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Region profile code',
            hintText: 'e.g. IN — supplies phone, document, and retention defaults (ADR-0007)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_contact_email_field'),
          controller: _contactEmail,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Contact email (optional)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
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
          decoration: const InputDecoration(
            labelText: 'Contact phone (optional)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('org_onboarding_create_org_button'),
          // Stays enabled on empty fields — the bloc answers with a specific message rather
          // than a disabled control explaining nothing (ACCESSIBILITY.md §Operable).
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const OnboardingButtonSpinner(semanticsLabel: 'Creating organization')
              : const Text('Create organization'),
        ),
      ],
    );
  }
}
