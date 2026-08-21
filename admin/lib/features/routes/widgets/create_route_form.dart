import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';

/// Creates a route (RTE-001).
///
/// **Stops are not collected here.** A route needs at least two stops before it can carry
/// student assignments (BR-ROUTE-001), but adding them is a map-drag interaction (A-31, per
/// ADMIN_WEB.md) that a text form does a disservice to. This form creates the route's identity
/// only — code, name, and which bus normally runs it — which is everything the crew-assignment
/// flow (A-25) needs; stop entry is left for the map editor this console does not have yet.
///
/// `schoolId` and `defaultVehicleId` are plain fields for the same reason as
/// `CreateStaffForm`'s `schoolId`: no picker screens exist yet for either.
class CreateRouteForm extends StatefulWidget {
  const CreateRouteForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final void Function({
    required String schoolId,
    required String code,
    required String name,
    String? defaultVehicleId,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<CreateRouteForm> createState() => _CreateRouteFormState();
}

class _CreateRouteFormState extends State<CreateRouteForm> {
  final _schoolId = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _defaultVehicleId = TextEditingController();

  @override
  void dispose() {
    _schoolId.dispose();
    _code.dispose();
    _name.dispose();
    _defaultVehicleId.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      schoolId: _schoolId.text.trim(),
      code: _code.text,
      name: _name.text,
      defaultVehicleId: _defaultVehicleId.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Add route', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'Creates the route itself. Stops are added separately once the map editor exists — '
          'this is enough for assigning a driver or attendant to it today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('route_form_school_id_field'),
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
          key: const Key('route_form_code_field'),
          controller: _code,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Route code',
            hintText: 'e.g. R3',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('route_form_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Route name',
            hintText: 'e.g. Green Park — Morning',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('route_form_default_vehicle_id_field'),
          controller: _defaultVehicleId,
          enabled: !widget.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Default bus ID (optional)',
            hintText: 'The vehicle ID from the Vehicles screen',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('route_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('route_form_submit_button'),
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
