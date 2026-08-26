import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';

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
  static const _relationships = <String, String>{
    'MOTHER': 'Mother',
    'FATHER': 'Father',
    'GUARDIAN': 'Guardian',
    'GRANDPARENT': 'Grandparent',
    'AUNT_UNCLE': 'Aunt / Uncle',
    'OTHER': 'Other',
  };

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
        Text('Add parent', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'The phone number becomes their sign-in straight away — they open the parent app, '
          'enter their number, and get a one-time code. Enter it carefully.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('guardian_form_relationship_field'),
          initialValue: _relationshipType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Relationship',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          items: [
            for (final entry in _relationships.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
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
          decoration: const InputDecoration(
            labelText: 'First name',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_form_last_name_field'),
          controller: _lastName,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Last name',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_form_phone_field'),
          controller: _phone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone (parent-app sign-in)',
            hintText: 'e.g. 9990000001',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('guardian_form_email_field'),
          controller: _email,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (optional)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_view'),
          title: 'Can see this child',
          subtitle: 'View the child and their journey in the app',
          value: _canView,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canView = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_notify'),
          title: 'Receives notifications',
          subtitle: 'Boarding, arrival, and alert messages',
          value: _canReceiveNotifications,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canReceiveNotifications = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_handover'),
          title: 'Can collect the child',
          subtitle: 'Authorised to receive the child at the stop — needed before the '
              'child can be put on a bus',
          value: _canAuthoriseHandover,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canAuthoriseHandover = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_can_absence'),
          title: 'Can report an absence',
          subtitle: 'Tell the school the child will not travel',
          value: _canDeclareAbsence,
          onChanged: widget.isSubmitting
              ? null
              : (v) => setState(() => _canDeclareAbsence = v),
        ),
        _RightSwitch(
          fieldKey: const Key('guardian_form_is_primary'),
          title: 'Primary contact',
          subtitle: 'The first person the school reaches',
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
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('guardian_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? const OnboardingButtonSpinner(semanticsLabel: 'Adding')
                    : const Text('Add parent'),
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
