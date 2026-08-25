import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
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
          ],
        );
      },
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
      decoration: const InputDecoration(
        labelText: 'Organization',
        border: OutlineInputBorder(),
        constraints: BoxConstraints(minHeight: kAdminTouchTarget),
      ),
      hint: Text(state.isLoadingOrganizations ? 'Loading…' : 'Select an organization'),
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
      decoration: const InputDecoration(
        labelText: 'School',
        border: OutlineInputBorder(),
        constraints: BoxConstraints(minHeight: kAdminTouchTarget),
      ),
      hint: Text(
        waitingOnOrganization
            ? 'Select an organization first'
            : state.isLoadingSchools
                ? 'Loading…'
                : 'Select a school',
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
            'Could not load your organizations or schools.',
            style: theme.textTheme.bodyMedium?.copyWith(color: context.status.critical),
          ),
        ),
        TextButton(
          key: const Key('school_scope_retry_button'),
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
