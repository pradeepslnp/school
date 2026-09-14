import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import 'onboarding_button_spinner.dart';
import 'onboarding_form_section.dart';

/// Step 1: the organization's own details (TEN-001).
///
/// Owns its controllers and nothing else — validity and uniqueness are the server's decision
/// (BR-TEN-007), matching `CredentialsForm`'s split.
///
/// Grouped into identity, region, and contact, so the two fields that matter most — the name,
/// and the code that can never change — are read first and the optional contact details last.
/// The name comes before the code because that is the order an operator thinks in.
class CreateOrganizationForm extends StatefulWidget {
  const CreateOrganizationForm({
    super.key,
    required this.onSubmit,
    this.onCancel,
    this.error,
    this.isSubmitting = false,
  });

  final void Function({
    required String code,
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) onSubmit;

  /// Leaves the flow without creating anything. Null hides the control.
  final VoidCallback? onCancel;

  /// The last failure, rendered just above the actions — beside the button the operator will
  /// press again — rather than below them where it is easy to miss.
  final Widget? error;

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
    final l10n = context.l10n;
    final cancel = widget.onCancel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingFormSection(
          title: l10n.createOrgSectionIdentityTitle,
          description: l10n.createOrgSectionIdentityDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('org_onboarding_name_field'),
                controller: _name,
                autofocus: true,
                enabled: !widget.isSubmitting,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.createOrgNameLabel,
                  hintText: l10n.createOrgNameHint,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
              const SizedBox(height: AdminSpacing.md),
              OnboardingCompactField(
                maxWidth: 320,
                child: TextField(
                  key: const Key('org_onboarding_code_field'),
                  controller: _code,
                  enabled: !widget.isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.createOrgCodeLabel,
                    hintText: l10n.createOrgCodeHint,
                    helperText: l10n.createOrgCodeHelper,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                  ),
                ),
              ),
            ],
          ),
        ),
        const OnboardingSectionDivider(),
        OnboardingFormSection(
          title: l10n.createOrgSectionRegionTitle,
          description: l10n.createOrgSectionRegionDescription,
          child: OnboardingCompactField(
            maxWidth: 320,
            child: TextField(
              key: const Key('org_onboarding_region_field'),
              controller: _regionProfileCode,
              enabled: !widget.isSubmitting,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.createOrgRegionLabel,
                helperText: l10n.createOrgRegionHelper,
                border: const OutlineInputBorder(),
                constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
              ),
            ),
          ),
        ),
        const OnboardingSectionDivider(),
        OnboardingFormSection(
          title: l10n.createOrgSectionContactTitle,
          description: l10n.createOrgSectionContactDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('org_onboarding_contact_email_field'),
                controller: _contactEmail,
                enabled: !widget.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.createOrgContactEmailLabel,
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
                  labelText: l10n.createOrgContactPhoneLabel,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ],
          ),
        ),
        if (widget.error != null) widget.error!,
        OnboardingFormFooter(
          secondary: cancel == null
              ? null
              : TextButton(
                  key: const Key('org_onboarding_cancel_button'),
                  onPressed: widget.isSubmitting ? null : cancel,
                  child: Text(l10n.commonCancelButton),
                ),
          primary: FilledButton(
            key: const Key('org_onboarding_create_org_button'),
            // Stays enabled on empty fields — the bloc answers with a specific message rather
            // than a disabled control explaining nothing (ACCESSIBILITY.md §Operable).
            onPressed: widget.isSubmitting ? null : _submit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.createOrgContinueButton),
                const SizedBox(width: AdminSpacing.sm),
                if (widget.isSubmitting)
                  OnboardingButtonSpinner(semanticsLabel: l10n.createOrgCreatingSpinnerLabel)
                else
                  const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
