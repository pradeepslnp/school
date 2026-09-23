import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
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

  /// Only the staff who *are* the selected role. A driver cannot be rostered as an attendant or
  /// the reverse: `transport_staff.staff_type` is what the person is, and the licence check at
  /// trip start (BR-STAFF-001) only ever runs against the driver duty.
  List<CreatedStaff> get _candidates =>
      widget.staffOptions.where((staff) => staff.staffType == _role).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _autoSelectSingleCandidate();
  }

  void _autoSelectSingleCandidate() {
    final candidates = _candidates;
    _staffId = candidates.length == 1 ? candidates.first.id : null;
  }

  /// Changing the role clears the person. Keeping a stale id would submit a driver as the
  /// attendant — the exact mistake this form now exists to prevent.
  void _onRoleChanged(String role) {
    setState(() {
      _role = role;
      _autoSelectSingleCandidate();
    });
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
    final candidates = _candidates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.routeCrewAssignButton, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.sm),
        SegmentedButton<String>(
          key: const Key('duty_form_role_field'),
          segments: [
            ButtonSegment(value: 'DRIVER', label: Text(context.l10n.staffTypeDriver)),
            ButtonSegment(value: 'ATTENDANT', label: Text(context.l10n.staffTypeAttendant)),
          ],
          selected: {_role},
          onSelectionChanged: widget.isSubmitting
              ? null
              : (selection) => _onRoleChanged(selection.first),
        ),
        const SizedBox(height: AdminSpacing.md),
        DropdownButtonFormField<String>(
          key: const Key('duty_form_staff_id_field'),
          initialValue: _staffId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.dutyFormStaffLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(
            candidates.isEmpty
                ? (_role == 'DRIVER'
                    ? context.l10n.dutyFormNoDriversHint
                    : context.l10n.dutyFormNoAttendantsHint)
                : context.l10n.dutyFormSelectPersonHint,
          ),
          items: [
            // No staff-type suffix on the option any more: every name in this list is the role
            // already selected above, so repeating it is noise the operator has to read past.
            for (final staff in candidates)
              DropdownMenuItem(value: staff.id, child: Text(staff.displayName)),
          ],
          onChanged: widget.isSubmitting || candidates.isEmpty
              ? null
              : (value) => setState(() => _staffId = value),
        ),
        const SizedBox(height: AdminSpacing.md),
        SegmentedButton<String>(
          key: const Key('duty_form_direction_field'),
          segments: [
            ButtonSegment(value: 'BOTH', label: Text(context.l10n.directionBoth)),
            ButtonSegment(value: 'PICKUP', label: Text(context.l10n.studentDetailDirectionPickup)),
            ButtonSegment(value: 'DROP', label: Text(context.l10n.studentDetailDirectionDrop)),
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
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('duty_form_submit_button'),
                onPressed: widget.isSubmitting || _staffId == null ? null : _submit,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(semanticsLabel: context.l10n.dutyFormAssigningSpinnerLabel)
                    : Text(context.l10n.dutyFormAssignButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
