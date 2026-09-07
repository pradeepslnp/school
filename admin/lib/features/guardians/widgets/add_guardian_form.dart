import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../domain/guardian_models.dart';

/// Adds a parent to a student (GRD-001, screen A-11).
///
/// The phone entered here becomes the parent's sign-in immediately — there is no separate
/// invite step — so the helper text says so, and the number is the one field an operator must
/// get right for the right person to be able to open the app.
///
/// Rights are shown as plain switches with the schema's own defaults: a parent can see their
/// child and be notified unless you turn those off, and cannot authorise a handover or declare
/// an absence unless you turn those on. "Can collect the child" is deliberately off by default
/// — it is the one that lets someone take the child off the bus (BR-GRD-001).
class AddGuardianForm extends StatefulWidget {
  const AddGuardianForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final void Function({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String relationshipType,
    required bool canView,
    required bool canReceiveNotifications,
    required bool canAuthoriseHandover,
    required bool canDeclareAbsence,
    required bool isPrimary,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<AddGuardianForm> createState() => _AddGuardianFormState();
}

class _AddGuardianFormState extends State<AddGuardianForm> {
  // Codes only — display labels come from `guardianRelationshipLabel` (shared with
  // `GuardianTile`), resolved per build against the active locale.
  static const _relationshipCodes = <String>[
    'MOTHER',
    'FATHER',
    'GUARDIAN',
    'GRANDPARENT',
    'AUNT_UNCLE',
    'OTHER',
  ];

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _relationshipType = 'MOTHER';

  bool _canView = true;
  bool _canReceiveNotifications = true;
  bool _canAuthoriseHandover = false;
  bool _canDeclareAbsence = false;
  bool _isPrimary = false;

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
      relationshipType: _relationshipType,
      canView: _canView,
      canReceiveNotifications: _canReceiveNotifications,
      canAuthoriseHandover: _canAuthoriseHandover,
      canDeclareAbsence: _canDeclareAbsence,
      isPrimary: _isPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.addGuardianFormTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          context.l10n.addGuardianFormIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('guardian_form_relationship_field'),
          initialValue: _relationshipType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.addGuardianRelationshipLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          items: [
            for (final code in _relationshipCodes)
              DropdownMenuItem(
                value: code,
                child: Text(guardianRelationshipLabel(context.l10n, code)),
              ),
          ],
          onChanged: widget.isSubmitting
              ? null
              : (value) => setState(() => _relationshipType = value ?? 'OTHER'),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_form_first_name_field'),
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
          key: const Key('guardian_form_last_name_field'),
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
          key: const Key('guardian_form_phone_field'),
          controller: _phone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: context.l10n.addGuardianPhoneLabel,
            hintText: context.l10n.addGuardianPhoneHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_form_email_field'),
          controller: _email,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.l10n.addGuardianEmailLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_view'),
          title: context.l10n.addGuardianCanViewTitle,
          subtitle: context.l10n.addGuardianCanViewSubtitle,
          value: _canView,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canView = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_notify'),
          title: context.l10n.addGuardianCanNotifyTitle,
          subtitle: context.l10n.addGuardianCanNotifySubtitle,
          value: _canReceiveNotifications,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canReceiveNotifications = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_handover'),
          title: context.l10n.addGuardianCanHandoverTitle,
          subtitle: context.l10n.addGuardianCanHandoverSubtitle,
          value: _canAuthoriseHandover,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canAuthoriseHandover = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_absence'),
          title: context.l10n.addGuardianCanAbsenceTitle,
          subtitle: context.l10n.addGuardianCanAbsenceSubtitle,
          value: _canDeclareAbsence,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canDeclareAbsence = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_is_primary'),
          title: context.l10n.addGuardianPrimaryTitle,
          subtitle: context.l10n.addGuardianPrimarySubtitle,
          value: _isPrimary,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _isPrimary = v),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('guardian_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('guardian_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(
                        semanticsLabel: context.l10n.addGuardianSubmitSpinnerLabel,
                      )
                    : Text(context.l10n.addGuardianFormTitle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One right, as a labelled switch with an explanation of what it grants — colour and position
/// are never the only signal (DESIGN_SYSTEM.md), so each carries its own words.
class _RightSwitch extends StatelessWidget {
  const _RightSwitch({
    required this.fieldKey,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key fieldKey;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: fieldKey,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
