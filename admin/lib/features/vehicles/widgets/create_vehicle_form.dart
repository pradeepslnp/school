import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';

/// Registers a vehicle (FLT-001).
///
/// [schoolId] comes in already decided: the operator picked it on the Vehicles screen (via
/// `SchoolPickerField`, or their own single-school scope) before this dialog could even be
/// opened — see `VehicleListScreen`'s add button, which is disabled until a school is
/// selected. Asking for it again here, whether as free text or a second dropdown, would just
/// be the same choice made twice.
class CreateVehicleForm extends StatefulWidget {
  const CreateVehicleForm({
    super.key,
    required this.schoolId,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final String schoolId;

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
  final _registrationNo = TextEditingController();
  final _displayName = TextEditingController();
  final _seatingCapacity = TextEditingController();
  final _vendorName = TextEditingController();
  String _vehicleType = 'BUS';

  @override
  void dispose() {
    _registrationNo.dispose();
    _displayName.dispose();
    _seatingCapacity.dispose();
    _vendorName.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      schoolId: widget.schoolId,
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
        Text(context.l10n.vehicleListAddButton, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          context.l10n.createVehicleFormIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        SegmentedButton<String>(
          key: const Key('vehicle_form_type_field'),
          segments: [
            ButtonSegment(value: 'BUS', label: Text(context.l10n.vehicleTypeBus)),
            ButtonSegment(value: 'VAN', label: Text(context.l10n.vehicleTypeVan)),
            ButtonSegment(value: 'MINIBUS', label: Text(context.l10n.vehicleTypeMinibus)),
          ],
          selected: {_vehicleType},
          onSelectionChanged: widget.isSubmitting
              ? null
              : (selection) => setState(() => _vehicleType = selection.first),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_registration_no_field'),
          controller: _registrationNo,
          autofocus: true,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: context.l10n.createVehicleRegistrationNoLabel,
            hintText: context.l10n.createVehicleRegistrationNoHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_display_name_field'),
          controller: _displayName,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.createVehicleDisplayNameLabel,
            hintText: context.l10n.createVehicleDisplayNameHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_seating_capacity_field'),
          controller: _seatingCapacity,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.createVehicleSeatingCapacityLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('vehicle_form_vendor_name_field'),
          controller: _vendorName,
          enabled: !widget.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.l10n.createVehicleVendorNameLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('vehicle_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('vehicle_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(semanticsLabel: context.l10n.commonAddingSpinnerLabel)
                    : Text(context.l10n.commonAddButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
