import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_button_spinner.dart';

/// Edits one school's own details — name, timezone, location, geofence (TEN-002).
///
/// Shared between `OrganizationDetailsView` (reached via the Organizations list, A-40, by
/// `SUPER_ADMIN`/`ORG_ADMIN`) and `SchoolSettingsScreen` (A-41, reached directly by a
/// `SCHOOL_ADMIN` who holds `PERM-SCHOOL-EDIT` but not the `PERM-ORG-VIEW` that A-40 needs) —
/// one form, two entry points, so the two never drift on which fields a school edit covers.
class SchoolEditForm extends StatefulWidget {
  const SchoolEditForm({
    super.key,
    required this.school,
    required this.isSubmitting,
    required this.onSave,
  });

  final CreatedSchool school;
  final bool isSubmitting;
  final void Function({
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) onSave;

  @override
  State<SchoolEditForm> createState() => _SchoolEditFormState();
}

class _SchoolEditFormState extends State<SchoolEditForm> {
  late final _name = TextEditingController(text: widget.school.name);
  late final _timezone = TextEditingController(text: widget.school.timezone);
  late final _latitude =
      TextEditingController(text: widget.school.latitude.toString());
  late final _longitude =
      TextEditingController(text: widget.school.longitude.toString());
  late final _geofenceRadiusM =
      TextEditingController(text: widget.school.geofenceRadiusM.toString());

  @override
  void dispose() {
    _name.dispose();
    _timezone.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _geofenceRadiusM.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSave(
      name: _name.text,
      timezone: _timezone.text.trim(),
      latitude: double.tryParse(_latitude.text.trim()) ?? widget.school.latitude,
      longitude: double.tryParse(_longitude.text.trim()) ?? widget.school.longitude,
      geofenceRadiusM:
          int.tryParse(_geofenceRadiusM.text.trim()) ?? widget.school.geofenceRadiusM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CopyableIdField(
          label: context.l10n.schoolDetailsIdLabel,
          helperText: context.l10n.schoolDetailsIdHelper,
          value: widget.school.id,
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('school_details_code_field'),
          enabled: false,
          controller: TextEditingController(text: widget.school.code),
          decoration: InputDecoration(
            labelText: context.l10n.schoolDetailsCodeFixedLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('school_details_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.schoolFieldNameLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('school_details_timezone_field'),
          controller: _timezone,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.schoolFieldTimezoneLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('school_details_latitude_field'),
                controller: _latitude,
                enabled: !widget.isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.schoolFieldLatitudeLabel,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: TextField(
                key: const Key('school_details_longitude_field'),
                controller: _longitude,
                enabled: !widget.isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.schoolFieldLongitudeLabel,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('school_details_geofence_field'),
          controller: _geofenceRadiusM,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.l10n.schoolFieldGeofenceLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        FilledButton(
          key: const Key('school_details_save_button'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? OnboardingButtonSpinner(semanticsLabel: context.l10n.schoolDetailsSavingSpinnerLabel)
              : Text(context.l10n.schoolDetailsSaveButton),
        ),
      ],
    );
  }
}

/// A read-only id with a copy button — the school UUID is only ever generated by the server
/// (BR-TEN-007's fixed codes are human-readable, but nothing downstream accepts them: `POST
/// /transport-staff`, `/vehicles`, and `/routes` all take the UUID). Without a way to see and
/// copy it here, the only way to find it is a direct database query.
///
/// A plain bordered row, not a disabled [TextField] with a `suffixIcon` — a disabled
/// decorator is not a reliable place to put an interactive button, and a UUID plus an
/// explanatory sentence does not fit in a floating label anyway.
class _CopyableIdField extends StatelessWidget {
  const _CopyableIdField({
    required this.label,
    required this.helperText,
    required this.value,
  });

  final String label;
  final String helperText;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AdminSpacing.xs),
        Container(
          constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  key: const Key('school_details_id_value'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                key: const Key('school_details_id_copy_button'),
                icon: const Icon(Icons.copy, size: 18),
                tooltip: context.l10n.copyTooltip,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.copiedToClipboardSnackbar)),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          helperText,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
