import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_button_spinner.dart';
import 'school_edit_form.dart';

/// View and edit one organization plus its (at most one, in this view) school (TEN-001,
/// TEN-002).
///
/// Reached either as the last step of onboarding a new organization, or from the Organizations
/// list (A-41, `OrganizationListScreen`) reopening one that already exists — both paths land
/// here through the same bloc state, populated either way before this widget builds. The code
/// fields are shown but not editable: both are immutable once minted (BR-TEN-007).
class OrganizationDetailsView extends StatelessWidget {
  const OrganizationDetailsView({
    super.key,
    required this.organization,
    required this.school,
    required this.isSubmitting,
    required this.onOrganizationSave,
    required this.onSchoolSave,
    required this.onAddSchool,
    required this.onSkipSchool,
    required this.onStartAnother,
  });

  final CreatedOrganization organization;

  /// Null if no school was added yet.
  final CreatedSchool? school;

  final bool isSubmitting;

  final void Function({
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) onOrganizationSave;

  final void Function({
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) onSchoolSave;

  final void Function({
    required String code,
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) onAddSchool;

  final VoidCallback onSkipSchool;

  final VoidCallback onStartAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Organization details', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.md),
        _OrganizationEditForm(
          key: ValueKey('org_details_${organization.id}'),
          organization: organization,
          isSubmitting: isSubmitting,
          onSave: onOrganizationSave,
        ),
        const SizedBox(height: AdminSpacing.lg),
        const Divider(),
        const SizedBox(height: AdminSpacing.lg),
        Text('School', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.md),
        if (school != null)
          SchoolEditForm(
            key: ValueKey('school_details_${school!.id}'),
            school: school!,
            isSubmitting: isSubmitting,
            onSave: onSchoolSave,
          )
        else
          _AddSchoolPrompt(
            organization: organization,
            isSubmitting: isSubmitting,
            onAddSchool: onAddSchool,
            onSkip: onSkipSchool,
          ),
        const SizedBox(height: AdminSpacing.lg),
        const Divider(),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton.tonal(
          key: const Key('org_onboarding_start_another_button'),
          onPressed: isSubmitting ? null : onStartAnother,
          child: const Text('Onboard another organization'),
        ),
      ],
    );
  }
}

class _OrganizationEditForm extends StatefulWidget {
  const _OrganizationEditForm({
    super.key,
    required this.organization,
    required this.isSubmitting,
    required this.onSave,
  });

  final CreatedOrganization organization;
  final bool isSubmitting;
  final void Function({
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) onSave;

  @override
  State<_OrganizationEditForm> createState() => _OrganizationEditFormState();
}

class _OrganizationEditFormState extends State<_OrganizationEditForm> {
  late final _name = TextEditingController(text: widget.organization.name);
  late final _regionProfileCode =
      TextEditingController(text: widget.organization.regionProfileCode);
  late final _contactEmail =
      TextEditingController(text: widget.organization.contactEmail ?? '');
  late final _contactPhone =
      TextEditingController(text: widget.organization.contactPhone ?? '');

  @override
  void dispose() {
    _name.dispose();
    _regionProfileCode.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    widget.onSave(
      name: _name.text,
      regionProfileCode: _regionProfileCode.text,
      contactEmail: _contactEmail.text,
      contactPhone: _contactPhone.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('org_details_code_field'),
          enabled: false,
          controller: TextEditingController(text: widget.organization.code),
          decoration: const InputDecoration(
            labelText: 'Organization code (fixed, BR-TEN-007)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_details_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Organization name',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_details_region_field'),
          controller: _regionProfileCode,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Region profile code',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_details_contact_email_field'),
          controller: _contactEmail,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Contact email (optional)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_details_contact_phone_field'),
          controller: _contactPhone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Contact phone (optional)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        FilledButton(
          key: const Key('org_details_save_button'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const OnboardingButtonSpinner(semanticsLabel: 'Saving organization')
              : const Text('Save organization changes'),
        ),
      ],
    );
  }
}

/// Shown in place of the school edit form when the operator skipped step 2 — reuses the same
/// code/name/timezone/location fields, just still framed as adding rather than editing.
class _AddSchoolPrompt extends StatefulWidget {
  const _AddSchoolPrompt({
    required this.organization,
    required this.isSubmitting,
    required this.onAddSchool,
    required this.onSkip,
  });

  final CreatedOrganization organization;
  final bool isSubmitting;
  final void Function({
    required String code,
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) onAddSchool;
  final VoidCallback onSkip;

  @override
  State<_AddSchoolPrompt> createState() => _AddSchoolPromptState();
}

class _AddSchoolPromptState extends State<_AddSchoolPrompt> {
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
    widget.onAddSchool(
      code: _code.text,
      name: _name.text,
      timezone: _timezone.text.trim(),
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
        Text(
          'No school has been added yet. ${widget.organization.name} needs at least one '
          'before it can be used day to day (BR-TEN-002).',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_details_add_school_code_field'),
          controller: _code,
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
          key: const Key('org_details_add_school_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'School name',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_details_add_school_timezone_field'),
          controller: _timezone,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Timezone (IANA identifier)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('org_details_add_school_latitude_field'),
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
                key: const Key('org_details_add_school_longitude_field'),
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
          key: const Key('org_details_add_school_geofence_field'),
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
        const SizedBox(height: AdminSpacing.md),
        FilledButton(
          key: const Key('org_details_add_school_button'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const OnboardingButtonSpinner(semanticsLabel: 'Adding school')
              : const Text('Add school'),
        ),
        const SizedBox(height: AdminSpacing.sm),
        TextButton(
          key: const Key('org_details_skip_school_button'),
          onPressed: widget.isSubmitting ? null : widget.onSkip,
          child: const Text('Not now'),
        ),
      ],
    );
  }
}
