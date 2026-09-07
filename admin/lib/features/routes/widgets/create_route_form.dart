import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../../vehicles/domain/vehicle_models.dart';

/// Creates a route (RTE-001).
///
/// **Stops are not collected here.** A route needs at least two stops before it can carry
/// student assignments (BR-ROUTE-001), but adding them is a map-drag interaction (A-31, per
/// ADMIN_WEB.md) that a text form does a disservice to. This form creates the route's identity
/// only — code, name, and which bus normally runs it — which is everything the crew-assignment
/// flow (A-25) needs; stop entry is left for the map editor this console does not have yet.
///
/// [schoolId] comes in already decided: the operator picked it on the Routes screen (via
/// `SchoolPickerField`, or their own single-school scope) before this dialog could even be
/// opened — see `RouteListScreen`'s add button, which is disabled until a school is selected.
/// [vehicles] is that same school's fleet, fetched once when the dialog opens, so "which bus
/// normally runs it" is a pick from a real, current list rather than a pasted id nobody can
/// verify by eye.
class CreateRouteForm extends StatefulWidget {
  const CreateRouteForm({
    super.key,
    required this.schoolId,
    required this.vehicles,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  final String schoolId;
  final List<CreatedVehicle> vehicles;

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
  final _code = TextEditingController();
  final _name = TextEditingController();
  String? _defaultVehicleId;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      schoolId: widget.schoolId,
      code: _code.text,
      name: _name.text,
      defaultVehicleId: _defaultVehicleId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.routeListAddButton, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          context.l10n.createRouteIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('route_form_code_field'),
          controller: _code,
          autofocus: true,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.createRouteCodeLabel,
            hintText: context.l10n.createRouteCodeHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('route_form_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.createRouteNameLabel,
            hintText: context.l10n.createRouteNameHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        DropdownButtonFormField<String?>(
          key: const Key('route_form_default_vehicle_id_field'),
          initialValue: _defaultVehicleId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.createRouteDefaultVehicleLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(
            widget.vehicles.isEmpty
                ? context.l10n.createRouteNoVehiclesHint
                : context.l10n.noneOptionLabel,
          ),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(context.l10n.noneOptionLabel)),
            for (final vehicle in widget.vehicles)
              DropdownMenuItem<String?>(
                value: vehicle.id,
                child: Text(
                  context.l10n.createRouteVehicleOption(vehicle.displayName, vehicle.registrationNo),
                ),
              ),
          ],
          onChanged: widget.isSubmitting
              ? null
              : (value) => setState(() => _defaultVehicleId = value),
        ),
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('route_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('route_form_submit_button'),
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
