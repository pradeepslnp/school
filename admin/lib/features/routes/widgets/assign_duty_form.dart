import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';

/// Assigns a driver or attendant to a route's standing roster (STF-004).
///
/// `staffId` is a plain field — the Drivers screen (A-23) is where an operator finds it; no
/// combined picker exists yet, matching every other id field in this console.
class AssignDutyForm extends StatefulWidget {
  const AssignDutyForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final void Function({
    required String staffId,
    required String role,
    String? direction,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<AssignDutyForm> createState() => _AssignDutyFormState();
}

class _AssignDutyFormState extends State<AssignDutyForm> {
  final _staffId = TextEditingController();
  String _role = 'DRIVER';
  String _direction = 'BOTH';

  @override
  void dispose() {
    _staffId.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      staffId: _staffId.text.trim(),
      role: _role,
      direction: _direction == 'BOTH' ? null : _direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Assign crew', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.sm),
        TextField(
          key: const Key('duty_form_staff_id_field'),
          controller: _staffId,
          autofocus: true,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Staff ID',
            hintText: 'From the Drivers screen',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        SegmentedButton<String>(
          key: const Key('duty_form_role_field'),
          segments: const [
            ButtonSegment(value: 'DRIVER', label: Text('Driver')),
            ButtonSegment(value: 'ATTENDANT', label: Text('Attendant')),
          ],
          selected: {_role},
          onSelectionChanged:
              widget.isSubmitting ? null : (selection) => setState(() => _role = selection.first),
        ),
        const SizedBox(height: AdminSpacing.md),
        SegmentedButton<String>(
          key: const Key('duty_form_direction_field'),
          segments: const [
            ButtonSegment(value: 'BOTH', label: Text('Both')),
            ButtonSegment(value: 'PICKUP', label: Text('Pickup')),
            ButtonSegment(value: 'DROP', label: Text('Drop')),
          ],
          selected: {_direction},
          onSelectionChanged: widget.isSubmitting
              ? null
              : (selection) => setState(() => _direction = selection.first),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('duty_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('duty_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? const OnboardingButtonSpinner(semanticsLabel: 'Assigning')
                    : const Text('Assign'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
