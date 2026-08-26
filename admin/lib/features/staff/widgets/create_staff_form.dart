import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';

/// Registers a driver or attendant (STF-001) and, in the same request, provisions their
/// driver-app sign-in — see `CreateTransportStaffUseCase` on the backend.
///
/// [schoolId] comes in already decided: the operator picked it on the Drivers screen (via
/// `SchoolPickerField`, or their own single-school scope) before this dialog could even be
/// opened — see `StaffListScreen`'s add button, which is disabled until a school is selected.
/// Asking for it again here, whether as free text or a second dropdown, would just be the
/// same choice made twice.
class CreateStaffForm extends StatefulWidget {
  const CreateStaffForm({
    super.key,
    required this.schoolId,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final String schoolId;

  final void Function({
    required String schoolId,
    required String staffType,
    required String firstName,
    required String lastName,
    required String phone,
    String? employeeCode,
    String? vendorName,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<CreateStaffForm> createState() => _CreateStaffFormState();
}

class _CreateStaffFormState extends State<CreateStaffForm> {
  final _employeeCode = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _vendorName = TextEditingController();
  String _staffType = 'DRIVER';

  @override
  void dispose() {
    _employeeCode.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _vendorName.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      schoolId: widget.schoolId,
      staffType: _staffType,
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
        Text('Add driver or attendant', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'Creates the roster record and a working driver-app sign-in in one step — the '
          'phone number below is what they sign in with (phone + one-time code). Added to '
          'the school you have selected above.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        SegmentedButton<String>(
          key: const Key('staff_form_type_field'),
          segments: const [
            ButtonSegment(value: 'DRIVER', label: Text('Driver')),
            ButtonSegment(value: 'ATTENDANT', label: Text('Attendant')),
          ],
          selected: {_staffType},
          onSelectionChanged: widget.isSubmitting
              ? null
              : (selection) => setState(() => _staffType = selection.first),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('staff_form_first_name_field'),
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
          key: const Key('staff_form_last_name_field'),
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
          key: const Key('staff_form_phone_field'),
          controller: _phone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone (driver-app sign-in)',
            hintText: 'e.g. 9990000001',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('staff_form_employee_code_field'),
          controller: _employeeCode,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Employee code (optional)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('staff_form_vendor_name_field'),
          controller: _vendorName,
          enabled: !widget.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Vendor name (optional, for contracted staff)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('staff_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('staff_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? const OnboardingButtonSpinner(semanticsLabel: 'Adding')
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
