import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../bloc/school_scope_bloc.dart';
import '../bloc/school_scope_event.dart';
import '../bloc/school_scope_state.dart';

/// Picks which school a school-scoped list screen loads, for an operator with no single-school
/// scope (`AuthenticatedUser.schoolScopeId` null) — an `ORG_ADMIN` sees a School dropdown
/// alone; a `SUPER_ADMIN`, who oversees more than one organization, sees Organization first and
/// School once one is chosen.
///
/// Requires a [SchoolScopeBloc] above it in the tree, already seeded with `SchoolScopeStarted`
/// — each of the four Routes that use this (`StudentListRoute` and its siblings) provides its
/// own instance, and only when the screen actually needs one.
///
/// Calls [onSchoolSelected] whenever [SchoolScopeState.selectedSchoolId] changes to a school —
/// picked by the operator, or picked automatically the moment a fetched list holds exactly one
/// (`SchoolScopeBloc._loadSchools`): most schools on this platform are the only school in their
/// organization, and a dropdown with one option that still has to be opened is friction with
/// nothing behind it.
class SchoolPickerField extends StatelessWidget {
  const SchoolPickerField({super.key, required this.onSchoolSelected});

  final ValueChanged<String> onSchoolSelected;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SchoolScopeBloc, SchoolScopeState>(
      listenWhen: (previous, current) =>
          current.selectedSchoolId != null &&
          current.selectedSchoolId != previous.selectedSchoolId,
      listener: (context, state) => onSchoolSelected(state.selectedSchoolId!),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                child: _PickerError(
                  onRetry: () {
                    final bloc = context.read<SchoolScopeBloc>();
                    final organizationId = state.selectedOrganizationId;
                    // A known organization means the schools fetch is what failed — retry that
                    // alone rather than re-fetching organizations too. Null only happens while
                    // still resolving the very first organizations fetch (SUPER_ADMIN only; an
                    // ORG_ADMIN's organization is set before any await, see
                    // `SchoolScopeBloc._onStarted`).
                    if (organizationId != null) {
                      bloc.add(SchoolScopeOrganizationSelected(organizationId));
                    } else {
                      bloc.add(const SchoolScopeStarted());
                    }
                  },
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.showOrganizationPicker) ...[
                  Expanded(child: _OrganizationDropdown(state: state)),
                  const SizedBox(width: AdminSpacing.md),
                ],
                Expanded(child: _SchoolDropdown(state: state)),
              ],
            ),
            if (_isDeadEnd(state))
              Padding(
                padding: const EdgeInsets.only(top: AdminSpacing.sm),
                child: _NoSchoolsNotice(
                  // An operator who had to pick an organization is reaching across tenants;
                  // one who did not is simply looking at an organization with no schools yet.
                  crossTenant: state.showOrganizationPicker,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Whether the picker has finished and produced nothing to choose.
///
/// The screens behind this picker gate every write on a selected school, so an empty school
/// list is a dead end: the operator sees disabled buttons and no reason for them. Saying why
/// is the whole point — silence here is what makes the console look broken.
///
/// Deliberately excludes the loading and error paths: neither is final, and a "no schools"
/// message over a failed request would be wrong as well as unhelpful.
bool _isDeadEnd(SchoolScopeState state) =>
    !state.isLoadingOrganizations &&
    !state.isLoadingSchools &&
    state.error == null &&
    state.selectedOrganizationId != null &&
    state.schools.isEmpty;

/// Explains an empty school list, and what to do about it.
///
/// **The cross-tenant case is not a bug and not a permission the operator is missing.**
/// Schools are read under row-level security scoped to the caller's tenant (ADR-0001), while
/// organizations are listed through the deliberately cross-tenant `list_organizations()`
/// function added by `V12__organization_listing.sql` for platform operators. So a
/// `SUPER_ADMIN` can name every organization on the platform and open the schools of none of
/// them — including their own tenant's, because the platform organization owns no schools.
///
/// Rather than widen the tenant boundary to close the gap, the picker states it.
class _NoSchoolsNotice extends StatelessWidget {
  const _NoSchoolsNotice({required this.crossTenant});

  final bool crossTenant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AdminSpacing.sm),
        Expanded(
          child: Text(
            crossTenant
                ? context.l10n.schoolScopeCrossTenantNotice
                : context.l10n.schoolScopeNoSchoolsNotice,
            key: const Key('school_scope_no_schools_notice'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganizationDropdown extends StatelessWidget {
  const _OrganizationDropdown({required this.state});

  final SchoolScopeState state;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const Key('school_scope_organization_field'),
      initialValue: state.selectedOrganizationId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.schoolScopeOrganizationLabel,
        border: const OutlineInputBorder(),
        constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
      ),
      hint: Text(
        state.isLoadingOrganizations
            ? context.l10n.schoolScopeLoadingHint
            : context.l10n.schoolScopeSelectOrganizationHint,
      ),
      items: [
        for (final organization in state.organizations)
          DropdownMenuItem(value: organization.id, child: Text(organization.name)),
      ],
      onChanged: state.isLoadingOrganizations
          ? null
          : (organizationId) {
              if (organizationId == null) return;
              context
                  .read<SchoolScopeBloc>()
                  .add(SchoolScopeOrganizationSelected(organizationId));
            },
    );
  }
}

class _SchoolDropdown extends StatelessWidget {
  const _SchoolDropdown({required this.state});

  final SchoolScopeState state;

  @override
  Widget build(BuildContext context) {
    final waitingOnOrganization =
        state.showOrganizationPicker && state.selectedOrganizationId == null;

    return DropdownButtonFormField<String>(
      key: const Key('school_scope_school_field'),
      initialValue: state.selectedSchoolId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.schoolScopeLabel,
        border: const OutlineInputBorder(),
        constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
      ),
      hint: Text(
        waitingOnOrganization
            ? context.l10n.schoolScopeSelectOrganizationFirstHint
            : state.isLoadingSchools
                ? context.l10n.schoolScopeLoadingHint
                : context.l10n.schoolScopeSelectSchoolHint,
      ),
      items: [
        for (final school in state.schools)
          DropdownMenuItem(value: school.id, child: Text(school.name)),
      ],
      onChanged: waitingOnOrganization || state.isLoadingSchools
          ? null
          : (schoolId) {
              if (schoolId == null) return;
              context.read<SchoolScopeBloc>().add(SchoolScopeSchoolSelected(schoolId));
            },
    );
  }
}

class _PickerError extends StatelessWidget {
  const _PickerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.schoolScopeLoadError,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.status.critical),
          ),
        ),
        TextButton(
          key: const Key('school_scope_retry_button'),
          onPressed: onRetry,
          child: Text(context.l10n.commonRetryButton),
        ),
      ],
    );
  }
}
