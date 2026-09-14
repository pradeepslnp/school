import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/geo/plus_code.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_button_spinner.dart';
import 'onboarding_form_section.dart';

/// Adds a school to an organization (TEN-002) — as step 2 of onboarding, or later from the
/// organization's details when step 2 was skipped. One form for both routes in, so how a school's
/// location is set can never differ between them.
///
/// The location is entered as a **Plus Code** — what an operator can actually copy out of Google
/// Maps for a school — and it decodes to the same latitude/longitude the API has always taken.
/// Nothing downstream changes, and the geofence that drives arrival notifications (BR-ALERT-001)
/// is set from a real coordinate either way.
///
/// The coordinates are **shown, not typed**: the decoded latitude/longitude appear in the location
/// tile under the code, so the operator sees what will actually be stored before submitting.
///
/// Still no map picker — this console has no mapping dependency, and ADMIN_WEB.md does not require
/// one here. The server owns the real validation (`-90..90`, `-180..180`, `20..2000`); this form
/// only stops an obviously unparseable value from being submitted.
class CreateSchoolForm extends StatefulWidget {
  const CreateSchoolForm({
    super.key,
    required this.organization,
    required this.onSubmit,
    required this.onSkip,
    this.announceCreated = true,
    this.error,
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

  /// True as step 2 of onboarding: the form opens by confirming the organization was just
  /// created, takes focus, and offers to skip for now. False when reached from the details view,
  /// where it sits below the organization's own form — so it explains why a school is needed
  /// instead, and leaves focus where the operator put it.
  final bool announceCreated;

  /// See `CreateOrganizationForm.error`.
  final Widget? error;

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
    final resolved = _resolved;
    if (resolved == null) {
      setState(() => _plusCodeRejected = true);
      return;
    }
    widget.onSubmit(
      code: _code.text,
      name: _name.text,
      timezone: _timezone.text.trim(),
      latitude: resolved.latitude,
      longitude: resolved.longitude,
      // Unparseable text becomes 0 rather than blocking submission client-side — the server
      // rejects an out-of-range value with the specific field it did not like
      // (VALIDATION_INVALID_FORMAT), which is a better answer than a form that silently
      // refuses to enable a button.
      geofenceRadiusM: int.tryParse(_geofenceRadiusM.text.trim()) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.announceCreated) ...[
          _CreatedBanner(organization: widget.organization),
          const SizedBox(height: AdminSpacing.xl),
        ] else ...[
          Text(
            l10n.addSchoolPromptIntro(widget.organization.name),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
        ],
        OnboardingFormSection(
          title: l10n.createSchoolSectionSchoolTitle,
          description: l10n.createSchoolSectionSchoolDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('org_onboarding_school_name_field'),
                controller: _name,
                autofocus: widget.announceCreated,
                enabled: !widget.isSubmitting,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.schoolFieldNameLabel,
                  hintText: l10n.createSchoolNameHint,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
              const SizedBox(height: AdminSpacing.md),
              OnboardingCompactField(
                maxWidth: 320,
                child: TextField(
                  key: const Key('org_onboarding_school_code_field'),
                  controller: _code,
                  enabled: !widget.isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.createSchoolCodeLabel,
                    hintText: l10n.createSchoolCodeHint,
                    helperText: l10n.createSchoolCodeHelper,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                  ),
                ),
              ),
            ],
          ),
        ),
        const OnboardingSectionDivider(),
        OnboardingFormSection(
          title: l10n.createSchoolSectionLocationTitle,
          description: l10n.createSchoolSectionLocationDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('org_onboarding_school_plus_code_field'),
                controller: _plusCode,
                enabled: !widget.isSubmitting,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onChanged: _onPlusCodeChanged,
                decoration: InputDecoration(
                  labelText: l10n.schoolFieldPlusCodeLabel,
                  hintText: l10n.createSchoolPlusCodeHint,
                  prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                  errorText: _plusCodeRejected ? l10n.schoolFieldPlusCodeInvalid : null,
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
              const SizedBox(height: AdminSpacing.sm),
              _LocationStatus(resolved: _resolved),
              const SizedBox(height: AdminSpacing.lg),
              OnboardingCompactField(
                maxWidth: 240,
                child: TextField(
                  key: const Key('org_onboarding_school_geofence_field'),
                  controller: _geofenceRadiusM,
                  enabled: !widget.isSubmitting,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.createSchoolGeofenceLabel,
                    suffixText: l10n.unitMetresSuffix,
                    helperText: l10n.createSchoolGeofenceHelper,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                  ),
                ),
              ),
            ],
          ),
        ),
        const OnboardingSectionDivider(),
        OnboardingFormSection(
          title: l10n.createSchoolSectionTimeTitle,
          description: l10n.createSchoolSectionTimeDescription,
          child: OnboardingCompactField(
            maxWidth: 320,
            child: TextField(
              key: const Key('org_onboarding_school_timezone_field'),
              controller: _timezone,
              enabled: !widget.isSubmitting,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.createSchoolTimezoneLabel,
                helperText: l10n.createSchoolTimezoneHelper,
                border: const OutlineInputBorder(),
                constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
              ),
            ),
          ),
        ),
        if (widget.error != null) widget.error!,
        OnboardingFormFooter(
          secondary: TextButton(
            key: const Key('org_onboarding_skip_school_button'),
            onPressed: widget.isSubmitting ? null : widget.onSkip,
            child: Text(
              widget.announceCreated
                  ? l10n.createSchoolSkipForNowButton
                  : l10n.addSchoolPromptSkipButton,
            ),
          ),
          primary: FilledButton(
            key: const Key('org_onboarding_create_school_button'),
            onPressed: widget.isSubmitting ? null : _submit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.createSchoolSubmitButton),
                if (widget.isSubmitting) ...[
                  const SizedBox(width: AdminSpacing.sm),
                  OnboardingButtonSpinner(semanticsLabel: l10n.createSchoolAddingSpinnerLabel),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Confirms step 1 landed before asking for more — the operator should not have to infer from a
/// changed form that the organization now exists.
///
/// Navy container, not the safety green: an organization being created is a registry event, and
/// `GuardianStatusColors` stays reserved for where a child is (DESIGN_SYSTEM.md §Status colors).
class _CreatedBanner extends StatelessWidget {
  const _CreatedBanner({required this.organization});

  final CreatedOrganization organization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const Key('org_onboarding_created_banner'),
        padding: const EdgeInsets.all(AdminSpacing.md),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.task_alt, size: 22, color: scheme.onPrimaryContainer),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.createSchoolCreatedBannerTitle(
                      organization.name,
                      organization.code,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.xs),
                  Text(
                    context.l10n.createSchoolCreatedBannerBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the Plus Code field: how to find a code while none is entered, and what the code
/// resolved to once one is — the coordinates the geofence will actually be built from.
class _LocationStatus extends StatelessWidget {
  const _LocationStatus({required this.resolved});

  final PlusCodeLocation? resolved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final livery = context.livery;
    final l10n = context.l10n;
    final location = resolved;

    return Semantics(
      container: true,
      liveRegion: location != null,
      child: Container(
        padding: const EdgeInsets.all(AdminSpacing.md),
        decoration: BoxDecoration(
          color: livery.panelSubtle,
          border: Border.all(color: livery.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              location == null ? Icons.info_outline : Icons.check_circle,
              size: 20,
              color: location == null ? scheme.onSurfaceVariant : scheme.primary,
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: location == null
                  ? Text(
                      l10n.createSchoolPlusCodeGuide,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.createSchoolLocationFoundTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AdminSpacing.xs),
                        Text(
                          l10n.schoolFieldPlusCodeResolved(
                            location.latitude.toStringAsFixed(6),
                            location.longitude.toStringAsFixed(6),
                            location.precisionMetres.toString(),
                          ),
                          key: const Key('org_onboarding_school_plus_code_resolved'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
