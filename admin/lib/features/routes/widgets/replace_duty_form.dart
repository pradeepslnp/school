import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../../staff/domain/staff_models.dart';
import '../domain/duty_assignment_models.dart';

/// Puts a different driver or attendant on an existing duty (STF-004, screen A-25).
///
/// The person changes; the role and the direction do not — they belong to the duty being taken
/// over, and changing who drives and what they drive at once is two decisions.
///
/// **A reason is required.** Every driver and attendant change is recorded with why it happened,
/// so the office can answer "who was on that bus, and why did it change" months later. The reason
/// is also the only place the absence that prompted this is written down.
///
/// This changes the **standing roster** — who normally runs the route. A stand-in for a single
/// day belongs to that day's trip, which the platform cannot record yet; the form says so.
class ReplaceDutyForm extends StatefulWidget {
  const ReplaceDutyForm({
    super.key,
    required this.current,
    required this.staffOptions,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  /// The duty being taken over, including who holds it now.
  final CreatedDutyAssignment current;

  /// This route's own school's roster. The person already on the duty is not offered.
  final List<CreatedStaff> staffOptions;

  final void Function({required String staffId, required String reason}) onSubmit;
  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<ReplaceDutyForm> createState() => _ReplaceDutyFormState();
}

class _ReplaceDutyFormState extends State<ReplaceDutyForm> {
  final _reason = TextEditingController();
  String? _staffId;

  /// Everyone who could take this duty: the same role as the duty being replaced, and not the
  /// person already on it. Filtering by role matters as much here as on the assign form — a
  /// replacement is still a duty row, and the server refuses a mismatched one
  /// (`STAFF_ROLE_MISMATCH`).
  late final List<CreatedStaff> _options = widget.staffOptions
      .where((staff) =>
          staff.id != widget.current.staffId && staff.staffType == widget.current.role)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _reason.addListener(_onChanged);
    // Matching AssignDutyForm: a dropdown with one entry has nothing to decide.
    if (_options.length == 1) {
      _staffId = _options.first.id;
    }
  }

  @override
  void dispose() {
    _reason.removeListener(_onChanged);
    _reason.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSubmit =>
      !widget.isSubmitting && _staffId != null && _reason.text.trim().isNotEmpty;

  void _submit() {
    final staffId = _staffId;
    if (!_canSubmit || staffId == null) return;
    widget.onSubmit(staffId: staffId, reason: _reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final role = widget.current.role == 'DRIVER' ? l10n.staffTypeDriver : l10n.staffTypeAttendant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.replaceDutyTitle(widget.current.displayName, role),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          l10n.replaceDutyStandingRosterNote,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AdminSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('replace_duty_staff_field'),
          initialValue: _staffId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.replaceDutyStaffLabel(role),
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(
            _options.isEmpty ? l10n.dutyFormNoRosterHint : l10n.dutyFormSelectPersonHint,
          ),
          items: [
            for (final staff in _options)
              DropdownMenuItem<String>(
                value: staff.id,
                // No role suffix: every name here is the role named in the label above.
                child: Text(staff.displayName),
              ),
          ],
          onChanged: widget.isSubmitting || _options.isEmpty
              ? null
              : (value) => setState(() => _staffId = value),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('replace_duty_reason_field'),
          controller: _reason,
          enabled: !widget.isSubmitting,
          minLines: 2,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: l10n.replaceDutyReasonLabel,
            helperText: l10n.replaceDutyReasonHelper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('replace_duty_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('replace_duty_submit_button'),
                onPressed: _canSubmit ? _submit : null,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(semanticsLabel: l10n.commonSavingSpinnerLabel)
                    : Text(l10n.replaceDutySubmitButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
