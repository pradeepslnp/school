import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../../staff/domain/staff_models.dart';

/// Assigns a driver or attendant to a route's standing roster (STF-004).
///
/// [staffOptions] is that route's own school's roster, fetched once when the dialog opens
/// (see `RouteCrewDialog._openAssignForm`) — a name picked from a real, current list beats a
/// staff id copied from another screen and pasted here, which is what this used to require.
/// Auto-selects the only entry when there is exactly one, matching `SchoolPickerField`'s own
/// reasoning for skipping a dropdown that has nothing to decide.
class AssignDutyForm extends StatefulWidget {
  const AssignDutyForm({
    super.key,
    required this.staffOptions,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final List<CreatedStaff> staffOptions;

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
  String? _staffId;
  String _role = 'DRIVER';
  String _direction = 'BOTH';

  @override
  void initState() {
    super.initState();
    if (widget.staffOptions.length == 1) {
      _staffId = widget.staffOptions.first.id;
    }
  }

  void _submit() {
    if (widget.isSubmitting) return;
    final staffId = _staffId;
    if (staffId == null) return;
    widget.onSubmit(
      staffId: staffId,
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
        DropdownButtonFormField<String>(
          key: const Key('duty_form_staff_id_field'),
          initialValue: _staffId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Driver or attendant',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(
            widget.staffOptions.isEmpty ? 'No roster loaded for this school' : 'Select a person',
          ),
          items: [
            for (final staff in widget.staffOptions)
              DropdownMenuItem(
                value: staff.id,
                child: Text('${staff.displayName} · ${staff.staffType}'),
              ),
          ],
          onChanged: widget.isSubmitting || widget.staffOptions.isEmpty
              ? null
              : (value) => setState(() => _staffId = value),
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
                onPressed: widget.isSubmitting || _staffId == null ? null : _submit,
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
