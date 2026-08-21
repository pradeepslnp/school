import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';

/// Registers a vehicle (FLT-001).
///
/// `schoolId` is a plain field rather than a picker — same reasoning as `CreateStaffForm`: no
/// schools list/picker screen exists yet, so asking the operator for the id directly is the
/// smallest correct thing.
class CreateVehicleForm extends StatefulWidget {
  const CreateVehicleForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final void Function({
    required String schoolId,
    required String registrationNo,
    required String displayName,
    required String vehicleType,
    required int seatingCapacity,
    String? vendorName,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<CreateVehicleForm> createState() => _CreateVehicleFormState();
}

class _CreateVehicleFormState extends State<CreateVehicleForm> {
  final _schoolId = TextEditingController();
  final _registrationNo = TextEditingController();
  final _displayName = TextEditingController();
  final _seatingCapacity = TextEditingController();
  final _vendorName = TextEditingController();
  String _vehicleType = 'BUS';

  @override
  void dispose() {
    _schoolId.dispose();
    _registrationNo.dispose();
    _displayName.dispose();
    _seatingCapacity.dispose();
    _vendorName.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      schoolId: _schoolId.text.trim(),
      registrationNo: _registrationNo.text,
      displayName: _displayName.text,
      vehicleType: _vehicleType,
      seatingCapacity: int.tryParse(_seatingCapacity.text.trim()) ?? 0,
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
        Text('Add vehicle', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'The display name is what parents see in notifications — "Bus 12", not the plate '
          'number.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        SegmentedButton<String>(
          key: const Key('vehicle_form_type_field'),
          segments: const [
            ButtonSegment(value: 'BUS', label: Text('Bus')),
            ButtonSegment(value: 'VAN', label: Text('Van')),
            ButtonSegment(value: 'MINIBUS', label: Text('Minibus')),
          ],
          selected: {_vehicleType},
          onSelectionChanged: widget.isSubmitting
              ? null
              : (selection) => setState(() => _vehicleType = selection.first),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_school_id_field'),
          controller: _schoolId,
          autofocus: true,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'School ID',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_registration_no_field'),
          controller: _registrationNo,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Registration number',
            hintText: 'e.g. DL1PC1234',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_display_name_field'),
          controller: _displayName,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'e.g. Bus 12',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_seating_capacity_field'),
          controller: _seatingCapacity,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Seating capacity',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_vendor_name_field'),
          controller: _vendorName,
          enabled: !widget.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Vendor name (optional, for outsourced fleets)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('vehicle_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('vehicle_form_submit_button'),
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
