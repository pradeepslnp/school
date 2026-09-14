import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/onboarding_models.dart';
import 'create_school_form.dart';
import 'onboarding_button_spinner.dart';
import 'onboarding_form_section.dart';
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
    required this.actorRoles,
    required this.actorOrganizationId,
    required this.onOrganizationSave,
    required this.onSchoolSave,
    required this.onAddSchool,
    required this.onSkipSchool,
    required this.onStartAnother,
    required this.onSuspend,
    required this.onReactivate,
  });

  final CreatedOrganization organization;

  /// Null if no school was added yet.
  final CreatedSchool? school;

  final bool isSubmitting;

  /// The signed-in operator's own roles — gates the suspend/reactivate control to
  /// `SUPER_ADMIN`, the only role holding `PERM-ORG-SUSPEND` (PERMISSION_MATRIX.md). Hiding
  /// it for anyone else is UX only; the server enforces the real rule regardless
  /// (`OrganizationController.suspend`/`reactivate`).
  final List<String> actorRoles;

  /// The organization the signed-in operator's own account belongs to, or null if unknown.
  /// Suspend is withheld on it: suspending it would lock out every account able to reactivate
  /// it, so the server refuses (`SuspendOrganizationUseCase`, BR-TEN-006). UX only, like
  /// [actorRoles].
  final String? actorOrganizationId;

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

  /// Dispatches `OrganizationSuspendRequested` (TEN-004, BR-TEN-006). The confirmation
  /// dialog lives in this widget, not the bloc — matching `UserListScreen`'s
  /// `_confirmToggleStatus` for the same "irreversible-feeling action needs a pause" reason.
  final VoidCallback onSuspend;

  /// The reverse of [onSuspend].
  final VoidCallback onReactivate;

  bool get _canManageLifecycle => actorRoles.contains('SUPER_ADMIN');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrganizationLifecycleHeader(
          key: ValueKey('org_lifecycle_${organization.id}'),
          organization: organization,
          isSubmitting: isSubmitting,
          canManage: _canManageLifecycle,
          isOwnOrganization: organization.id == actorOrganizationId,
          onSuspend: onSuspend,
          onReactivate: onReactivate,
        ),
        const SizedBox(height: AdminSpacing.lg),
        Text(context.l10n.orgDetailsSectionTitle, style: theme.textTheme.titleLarge),
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
        Text(context.l10n.schoolScopeLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.md),
        if (school != null)
          SchoolEditForm(
            key: ValueKey('school_details_${school!.id}'),
            school: school!,
            isSubmitting: isSubmitting,
            onSave: onSchoolSave,
          )
        else
          CreateSchoolForm(
            organization: organization,
            isSubmitting: isSubmitting,
            announceCreated: false,
            onSubmit: onAddSchool,
            onSkip: onSkipSchool,
          ),
        const SizedBox(height: AdminSpacing.lg),
        const Divider(),
        const SizedBox(height: AdminSpacing.lg),
        // A way on to the next job, not the point of this page — so a quiet outlined button, not
        // a full-width bar competing with the save actions above it.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('org_onboarding_start_another_button'),
            onPressed: isSubmitting ? null : onStartAnother,
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.l10n.onboardingStartAnotherButton),
          ),
        ),
      ],
    );
  }
}

/// Status badge plus the suspend/reactivate control (TEN-004, BR-TEN-006).
///
/// A `CLOSED` organization is not expected to reach this view via any button this console
/// currently offers (see `Organization.suspend`/`reactivate` on the backend) — the badge
/// still renders correctly for it, but no lifecycle button does, since neither action is
/// valid from that state.
class _OrganizationLifecycleHeader extends StatelessWidget {
  const _OrganizationLifecycleHeader({
    super.key,
    required this.organization,
    required this.isSubmitting,
    required this.canManage,
    required this.isOwnOrganization,
    required this.onSuspend,
    required this.onReactivate,
  });

  final CreatedOrganization organization;
  final bool isSubmitting;
  final bool canManage;

  /// Whether this is the operator's own organization — Suspend is not offered on it. See
  /// `OrganizationDetailsView.actorOrganizationId`.
  final bool isOwnOrganization;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback onConfirmed,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancelButton),
          ),
          FilledButton(
            key: const Key('org_lifecycle_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;

    final (Color badgeColor, String badgeLabel) = switch (organization.status) {
      'SUSPENDED' => (status.critical, context.l10n.orgSuspendedChip),
      'CLOSED' => (theme.colorScheme.onSurfaceVariant, context.l10n.orgStatusClosed),
      _ => (status.safe, context.l10n.orgStatusActive),
    };

    return Row(
      children: [
        Container(
          key: const Key('org_lifecycle_status_badge'),
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.sm,
            vertical: AdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badgeLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (canManage && !isOwnOrganization && organization.status == 'ACTIVE')
          OutlinedButton.icon(
            key: const Key('org_lifecycle_suspend_button'),
            onPressed: isSubmitting
                ? null
                : () => _confirm(
                      context,
                      title: context.l10n.orgConfirmSuspendTitle(organization.name),
                      body: context.l10n.orgConfirmSuspendBody(organization.name),
                      confirmLabel: context.l10n.orgSuspendButton,
                      onConfirmed: onSuspend,
                    ),
            icon: const Icon(Icons.pause_circle_outline),
            label: Text(context.l10n.orgSuspendButton),
          )
        else if (canManage && organization.status == 'SUSPENDED')
          FilledButton.icon(
            key: const Key('org_lifecycle_reactivate_button'),
            onPressed: isSubmitting
                ? null
                : () => _confirm(
                      context,
                      title: context.l10n.orgConfirmReactivateTitle(organization.name),
                      body: context.l10n.orgConfirmReactivateBody(organization.name),
                      confirmLabel: context.l10n.orgReactivateButton,
                      onConfirmed: onReactivate,
                    ),
            icon: const Icon(Icons.play_circle_outline),
            label: Text(context.l10n.orgReactivateButton),
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
    final l10n = context.l10n;

    // The same identity / region / contact grouping as `CreateOrganizationForm`, so editing an
    // organization reads like creating one — and sits consistently above the add-school form.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingFormSection(
          title: l10n.createOrgSectionIdentityTitle,
          description: l10n.createOrgSectionIdentityDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('org_details_name_field'),
                controller: _name,
                enabled: !widget.isSubmitting,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.createOrgNameLabel,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
              const SizedBox(height: AdminSpacing.md),
              OnboardingCompactField(
                maxWidth: 320,
                child: TextField(
                  key: const Key('org_details_code_field'),
                  enabled: false,
                  controller: TextEditingController(text: widget.organization.code),
                  decoration: InputDecoration(
                    labelText: l10n.orgDetailsCodeFixedLabel,
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
          title: l10n.createOrgSectionRegionTitle,
          description: l10n.createOrgSectionRegionDescription,
          child: OnboardingCompactField(
            maxWidth: 320,
            child: TextField(
              key: const Key('org_details_region_field'),
              controller: _regionProfileCode,
              enabled: !widget.isSubmitting,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.createOrgRegionLabel,
                helperText: l10n.createOrgRegionHelper,
                border: const OutlineInputBorder(),
                constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
              ),
            ),
          ),
        ),
        const OnboardingSectionDivider(),
        OnboardingFormSection(
          title: l10n.createOrgSectionContactTitle,
          description: l10n.createOrgSectionContactDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('org_details_contact_email_field'),
                controller: _contactEmail,
                enabled: !widget.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.createOrgContactEmailLabel,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
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
                decoration: InputDecoration(
                  labelText: l10n.createOrgContactPhoneLabel,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ],
          ),
        ),
        OnboardingFormFooter(
          primary: FilledButton(
            key: const Key('org_details_save_button'),
            onPressed: widget.isSubmitting ? null : _submit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.orgDetailsSaveButton),
                if (widget.isSubmitting) ...[
                  const SizedBox(width: AdminSpacing.sm),
                  OnboardingButtonSpinner(semanticsLabel: l10n.orgDetailsSavingSpinnerLabel),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
