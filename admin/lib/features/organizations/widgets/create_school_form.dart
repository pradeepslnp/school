import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_button_spinner.dart';

/// Step 2: the organization's first school (TEN-002).
///
/// Latitude, longitude, and geofence radius are entered as plain numbers rather than a map
/// picker — this console has no mapping dependency yet, and ADMIN_WEB.md does not require
/// one for this screen. The server still owns the real validation (`-90..90`, `-180..180`,
/// `20..2000`); this form only stops an obviously unparseable value from being submitted.
class CreateSchoolForm extends StatefulWidget {
  const CreateSchoolForm({
    super.key,
    required this.organization,
    required this.onSubmit,
    required this.onSkip,
    this.isSubmitting = false,
  });

  final CreatedOrganization organization;

  final void Function({
    required String code,
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) onSubmit;

  final VoidCallback onSkip;

  final bool isSubmitting;

  @override
  State<CreateSchoolForm> createState() => _CreateSchoolFormState();
}

class _CreateSchoolFormState extends State<CreateSchoolForm> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _timezone = TextEditingController(text: 'Asia/Kolkata');
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _geofenceRadiusM = TextEditingController(text: '150');

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _timezone.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _geofenceRadiusM.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSubmit(
      code: _code.text,
      name: _name.text,
      timezone: _timezone.text.trim(),
      // Unparseable text becomes 0 rather than blocking submission client-side — the server
      // rejects an out-of-range value with the specific field it did not like
      // (VALIDATION_INVALID_FORMAT), which is a better answer than a form that silently
      // refuses to enable a button.
      latitude: double.tryParse(_latitude.text.trim()) ?? 0,
      longitude: double.tryParse(_longitude.text.trim()) ?? 0,
      geofenceRadiusM: int.tryParse(_geofenceRadiusM.text.trim()) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step 2 of 2 — First school', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          '${widget.organization.name} (${widget.organization.code}) was created. An '
          'organization needs at least one school before it can be used day to day '
          '(BR-TEN-002) — add one now, or come back to it later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('org_onboarding_school_code_field'),
          controller: _code,
          autofocus: true,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'School code',
            hintText: 'e.g. GW-MAIN',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_school_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'School name',
            hintText: 'e.g. Greenwood Main Campus',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_school_timezone_field'),
          controller: _timezone,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Timezone (IANA identifier)',
            hintText: 'e.g. Asia/Kolkata',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('org_onboarding_school_latitude_field'),
                controller: _latitude,
                enabled: !widget.isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                  constraints: BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: TextField(
                key: const Key('org_onboarding_school_longitude_field'),
                controller: _longitude,
                enabled: !widget.isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                  constraints: BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_school_geofence_field'),
          controller: _geofenceRadiusM,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Geofence radius (metres, 20–2000)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('org_onboarding_create_school_button'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const OnboardingButtonSpinner(semanticsLabel: 'Adding school')
              : const Text('Add school'),
        ),
        const SizedBox(height: AdminSpacing.sm),
        TextButton(
          key: const Key('org_onboarding_skip_school_button'),
          onPressed: widget.isSubmitting ? null : widget.onSkip,
          child: const Text('Finish without adding a school'),
        ),
      ],
    );
  }
}
