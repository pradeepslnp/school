import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../bloc/organization_list_bloc.dart';
import '../bloc/organization_list_event.dart';
import '../bloc/organization_list_state.dart';
import '../domain/onboarding_models.dart';

/// A-41 — Organizations: every organization on the platform, `SUPER_ADMIN` only (TEN-001).
///
/// The landing screen for A-40's destination now that there is more than one organization to
/// manage — see `ConsoleDestinations`' documentation on why a platform operator lands here
/// rather than on an A-01 dashboard built for school-level staff.
///
/// Holds no state and makes no decisions, matching `OrganizationOnboardingScreen`: it renders
/// [OrganizationListState] and reports what the operator did. Navigating to create or view an
/// organization is a plain [Navigator] push, not a location change — see `OrganizationListRoute`
/// and `ConsoleRouterDelegate`'s own note that its location-based routing is due for revisit
/// once a second screen actually needs it; this one does not.
class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({
    super.key,
    required this.onAddOrganization,
    required this.onOpenOrganization,
  });

  final VoidCallback onAddOrganization;
  final ValueChanged<CreatedOrganization> onOpenOrganization;

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrganizationListBloc>().add(const OrganizationListRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Organizations', style: theme.textTheme.headlineSmall),
              ),
              FilledButton.icon(
                key: const Key('org_list_add_button'),
                onPressed: widget.onAddOrganization,
                icon: const Icon(Icons.add),
                label: const Text('Add organization'),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.lg),
          Expanded(
            child: BlocBuilder<OrganizationListBloc, OrganizationListState>(
              builder: (context, state) {
                if (state.isLoading && state.organizations.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading organizations',
                    ),
                  );
                }

                if (state.error != null && state.organizations.isEmpty) {
                  return _ListError(
                    onRetry: () => context
                        .read<OrganizationListBloc>()
                        .add(const OrganizationListRequested()),
                  );
                }

                if (state.organizations.isEmpty) {
                  return Center(
                    child: Text(
                      'No organizations yet. Add the first one to get started.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return _OrganizationTable(
                  organizations: state.organizations,
                  onOpenOrganization: widget.onOpenOrganization,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationTable extends StatelessWidget {
  const _OrganizationTable({
    required this.organizations,
    required this.onOpenOrganization,
  });

  final List<CreatedOrganization> organizations;
  final ValueChanged<CreatedOrganization> onOpenOrganization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        key: const Key('org_list_table'),
        itemCount: organizations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final organization = organizations[index];
          return ListTile(
            key: Key('org_list_row_${organization.id}'),
            minVerticalPadding: AdminSpacing.md,
            title: Text(organization.name),
            subtitle: Text('${organization.code} · ${organization.regionProfileCode}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (organization.isSuspended) _SuspendedChip(theme: theme),
                const SizedBox(width: AdminSpacing.sm),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => onOpenOrganization(organization),
          );
        },
      ),
    );
  }
}

/// A small "Suspended" flag on the organizations list (A-41) so an operator scanning the
/// whole list spots a suspended organization without opening it — the full status badge with
/// its Active/Closed states lives on the details view (`_OrganizationLifecycleHeader`);
/// nothing else on this list is worth flagging at a glance.
class _SuspendedChip extends StatelessWidget {
  const _SuspendedChip({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = context.status.critical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Suspended',
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = context.status.critical;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: color, size: 32),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'That could not be loaded right now. Try again shortly.',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
          const SizedBox(height: AdminSpacing.md),
          OutlinedButton(
            key: const Key('org_list_retry_button'),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
