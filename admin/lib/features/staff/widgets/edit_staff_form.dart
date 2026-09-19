import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../domain/staff_models.dart';

/// Edits an existing driver or attendant's contact and record-keeping details (STF-001).
///
/// `staffType` is shown but fixed, not editable — see `UpdateTransportStaffUseCase`'s own
/// documentation for why a type change is not offered as an edit (it would silently invalidate
/// credential-class checks already recorded against this staff member). Matches
/// `OrganizationDetailsView`'s treatment of fixed codes for the same reasoning.
class EditStaffForm extends StatefulWidget {
  const EditStaffForm({
    super.key,
    required this.staff,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final CreatedStaff staff;

  final void Function({
    required String firstName,
    required String lastName,
    required String phone,
    String? employeeCode,
    String? vendorName,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<EditStaffForm> createState() => _EditStaffFormState();
}

class _EditStaffFormState extends State<EditStaffForm> {
  late final _firstName = TextEditingController(text: widget.staff.firstName);
  late final _lastName = TextEditingController(text: widget.staff.lastName);
  late final _phone = TextEditingController(text: widget.staff.phone);
  late final _employeeCode = TextEditingController(text: widget.staff.employeeCode ?? '');
  late final _vendorName = TextEditingController(text: widget.staff.vendorName ?? '');

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _employeeCode.dispose();
    _vendorName.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      firstName: _firstName.text,
      lastName: _lastName.text,
      phone: _phone.text,
      employeeCode: _employeeCode.text,
      vendorName: _vendorName.text,
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
          context.l10n.editStaffTitle(widget.staff.displayName),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          widget.staff.staffType == 'DRIVER'
              ? context.l10n.staffTypeDriver
              : context.l10n.staffTypeAttendant,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('staff_edit_first_name_field'),
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
          key: const Key('staff_edit_last_name_field'),
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
          key: const Key('staff_edit_phone_field'),
          controller: _phone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: context.l10n.staffPhoneLabel,
            // BR-IAM-014: said before saving, because it signs someone out.
            helperText: context.l10n.staffEditPhoneHelper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('staff_edit_employee_code_field'),
          controller: _employeeCode,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.staffEmployeeCodeLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('staff_edit_vendor_name_field'),
          controller: _vendorName,
          enabled: !widget.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.l10n.staffVendorNameLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('staff_edit_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('staff_edit_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(semanticsLabel: context.l10n.commonSavingSpinnerLabel)
                    : Text(context.l10n.commonSaveChangesButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
