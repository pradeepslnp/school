import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/geo/plus_code.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_button_spinner.dart';

/// Step 2: the organization's first school (TEN-002).
///
/// The location can be entered either as a **Plus Code** or as raw coordinates. A Plus Code is
/// what an operator can actually copy out of Google Maps for a school, and it decodes to the
/// same latitude/longitude the API has always taken — nothing downstream changes, and the
/// geofence that drives arrival notifications (BR-ALERT-001) is set from a real coordinate
/// either way.
///
/// The coordinates are **shown, not typed**: a Plus Code is the single source of the school's
/// location, and the decoded latitude/longitude is displayed beneath it so the operator can see
/// what will actually be stored before submitting.
///
/// Still no map picker — this console has no mapping dependency, and ADMIN_WEB.md does not
/// require one here. The server owns the real validation (`-90..90`, `-180..180`, `20..2000`);
/// this form only stops an obviously unparseable value from being submitted.
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
  final _geofenceRadiusM = TextEditingController(text: '150');
  final _plusCode = TextEditingController();

  /// What the typed Plus Code resolved to, or null when the field is empty or incomplete.
  PlusCodeLocation? _resolved;

  /// True once the operator has typed something that is not yet a usable full code — used to
  /// explain the most common mistake (a short code) rather than leaving the field silent.
  bool _plusCodeRejected = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _timezone.dispose();
    _geofenceRadiusM.dispose();
    _plusCode.dispose();
    super.dispose();
  }

  /// Decodes the Plus Code and fills the coordinate fields from it.
  ///
  /// Writes into the same controllers the operator can edit by hand, so what is submitted is
  /// always exactly what is on screen — there is no hidden second source of the location.
  void _onPlusCodeChanged(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _resolved = null;
        _plusCodeRejected = false;
      });
      return;
    }

    final decoded = PlusCode.decode(trimmed);
    setState(() {
      _resolved = decoded;
      // Only complain once the code is long enough to be a full one; every code is
      // incomplete while it is still being typed.
      _plusCodeRejected = decoded == null && trimmed.length >= 9;
    });

  }

  void _submit() {
    if (widget.isSubmitting) return;

    // No resolved location, no submission. Before this, an empty coordinate field parsed to
    // 0 and the server accepted it: 0, 0 is a valid coordinate in the Gulf of Guinea, so a
    // school created that way got a geofence in the Atlantic and would never fire an arrival
    // notification (BR-ALERT-001). A missing location must fail loudly here, not silently
    // succeed as a wrong one.
    if (_resolved == null) {
      setState(() => _plusCodeRejected = true);
      return;
    }
    widget.onSubmit(
      code: _code.text,
      name: _name.text,
      timezone: _timezone.text.trim(),
      // Unparseable text becomes 0 rather than blocking submission client-side — the server
      // rejects an out-of-range value with the specific field it did not like
      // (VALIDATION_INVALID_FORMAT), which is a better answer than a form that silently
      // refuses to enable a button.
      latitude: _resolved?.latitude ?? 0,
      longitude: _resolved?.longitude ?? 0,
      geofenceRadiusM: int.tryParse(_geofenceRadiusM.text.trim()) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.createSchoolStepTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          context.l10n.createSchoolIntro(widget.organization.name, widget.organization.code),
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
          decoration: InputDecoration(
            labelText: context.l10n.createSchoolCodeLabel,
            hintText: context.l10n.createSchoolCodeHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_school_name_field'),
          controller: _name,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.schoolFieldNameLabel,
            hintText: context.l10n.createSchoolNameHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_school_timezone_field'),
          controller: _timezone,
          enabled: !widget.isSubmitting,
          decoration: InputDecoration(
            labelText: context.l10n.schoolFieldTimezoneLabel,
            hintText: context.l10n.createSchoolTimezoneHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_school_plus_code_field'),
          controller: _plusCode,
          enabled: !widget.isSubmitting,
          textCapitalization: TextCapitalization.characters,
          onChanged: _onPlusCodeChanged,
          decoration: InputDecoration(
            labelText: context.l10n.schoolFieldPlusCodeLabel,
            helperText: context.l10n.schoolFieldPlusCodeHelp,
            helperMaxLines: 3,
            errorText: _plusCodeRejected
                ? context.l10n.schoolFieldPlusCodeInvalid
                : null,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        if (_resolved != null) ...[
          const SizedBox(height: AdminSpacing.sm),
          // The coordinates are shown, not typed. They are what actually reaches the API and
          // what the geofence is built from, so the operator sees the consequence of the code
          // they entered rather than trusting it silently.
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.schoolFieldPlusCodeResolved(
                    _resolved!.latitude.toStringAsFixed(6),
                    _resolved!.longitude.toStringAsFixed(6),
                    _resolved!.precisionMetres.toString(),
                  ),
                  key: const Key('org_onboarding_school_plus_code_resolved'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('org_onboarding_school_geofence_field'),
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
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('org_onboarding_create_school_button'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? OnboardingButtonSpinner(semanticsLabel: context.l10n.createSchoolAddingSpinnerLabel)
              : Text(context.l10n.createSchoolSubmitButton),
        ),
        const SizedBox(height: AdminSpacing.sm),
        TextButton(
          key: const Key('org_onboarding_skip_school_button'),
          onPressed: widget.isSubmitting ? null : widget.onSkip,
          child: Text(context.l10n.createSchoolSkipButton),
        ),
      ],
    );
  }
}
