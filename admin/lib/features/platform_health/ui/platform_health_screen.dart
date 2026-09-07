import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../bloc/platform_health_bloc.dart';
import '../bloc/platform_health_event.dart';
import '../bloc/platform_health_state.dart';
import '../domain/platform_health_models.dart';

/// A-62 — Platform health: a quick pulse check for a platform operator (`SUPER_ADMIN` only),
/// not an infrastructure monitoring dashboard.
///
/// **Scope is deliberately narrow.** This answers two questions a platform operator
/// (Deepak, PERSONAS.md) actually has a use for: "is the platform basically working" and "how
/// many organizations would notice if it were not". It does not show JVM heap, disk space, or
/// request rates — nothing in this platform collects those today, and they would not help
/// Deepak decide what to do next even if it did. Said plainly on the screen itself, so nobody
/// mistakes a green checkmark here for full observability.
class PlatformHealthScreen extends StatelessWidget {
  const PlatformHealthScreen({super.key});

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
                child: Text(context.l10n.platformHealthTitle, style: theme.textTheme.headlineSmall),
              ),
              BlocBuilder<PlatformHealthBloc, PlatformHealthState>(
                builder: (context, state) => OutlinedButton.icon(
                  key: const Key('platform_health_refresh_button'),
                  onPressed: state.isLoading
                      ? null
                      : () => context
                          .read<PlatformHealthBloc>()
                          .add(const PlatformHealthRequested()),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.platformHealthRefreshButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.xs),
          Text(
            context.l10n.platformHealthIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
          Expanded(
            child: BlocBuilder<PlatformHealthBloc, PlatformHealthState>(
              builder: (context, state) {
                final health = state.health;

                if (state.isLoading && health == null) {
                  return Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: context.l10n.platformHealthCheckingLabel,
                    ),
                  );
                }

                if (health == null) {
                  return _HealthError(
                    onRetry: () => context
                        .read<PlatformHealthBloc>()
                        .add(const PlatformHealthRequested()),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusCard(health: health),
                      const SizedBox(height: AdminSpacing.lg),
                      Text(
                        context.l10n.platformHealthOrganizationsHeading,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      _OrganizationCounts(health: health),
                      const SizedBox(height: AdminSpacing.md),
                      Text(
                        context.l10n.platformHealthCheckedAt(_relativeTime(context, health.checkedAt)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A friendly relative timestamp — "just now", "3 minutes ago" — rather than a raw ISO
/// string, using the generated plural rules (`AppLocalizations`) rather than a hand-rolled
/// singular/plural check (ADR-0013).
String _relativeTime(BuildContext context, DateTime checkedAt) {
  final l10n = context.l10n;
  final difference = DateTime.now().toUtc().difference(checkedAt.toUtc());
  if (difference.inSeconds < 5) return l10n.platformHealthJustNow;
  if (difference.inMinutes < 1) return l10n.platformHealthSecondsAgo(difference.inSeconds);
  if (difference.inMinutes < 60) return l10n.platformHealthMinutesAgo(difference.inMinutes);
  return l10n.platformHealthHoursAgo(difference.inHours);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.health});

  final PlatformHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reachable = health.databaseReachable;
    final color = reachable ? context.status.safe : context.status.critical;

    return Card(
      key: Key(reachable ? 'platform_health_status_ok' : 'platform_health_status_degraded'),
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Row(
          children: [
            Icon(
              reachable ? Icons.check_circle_outline : Icons.warning_amber_outlined,
              color: color,
              size: 32,
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reachable
                        ? context.l10n.platformHealthReachableTitle
                        : context.l10n.platformHealthDegradedTitle,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reachable
                        ? context.l10n.platformHealthReachableBody
                        : context.l10n.platformHealthDegradedBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _OrganizationCounts extends StatelessWidget {
  const _OrganizationCounts({required this.health});

  final PlatformHealth health;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CountTile(
            key: const Key('platform_health_total_tile'),
            label: context.l10n.platformHealthCountTotal,
            count: health.totalOrganizations,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: AdminSpacing.md),
        Expanded(
          child: _CountTile(
            key: const Key('platform_health_active_tile'),
            label: context.l10n.platformHealthCountActive,
            count: health.activeOrganizations,
            color: context.status.safe,
          ),
        ),
        const SizedBox(width: AdminSpacing.md),
        Expanded(
          child: _CountTile(
            key: const Key('platform_health_suspended_tile'),
            label: context.l10n.platformHealthCountSuspended,
            count: health.suspendedOrganizations,
            color: health.suspendedOrganizations > 0
                ? context.status.critical
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AdminSpacing.md),
        Expanded(
          child: _CountTile(
            key: const Key('platform_health_closed_tile'),
            label: context.l10n.platformHealthCountClosed,
            count: health.closedOrganizations,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthError extends StatelessWidget {
  const _HealthError({required this.onRetry});

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
            context.l10n.errorGenericRetryShortly,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
          const SizedBox(height: AdminSpacing.md),
          OutlinedButton(
            key: const Key('platform_health_retry_button'),
            onPressed: onRetry,
            child: Text(context.l10n.commonRetryButton),
          ),
        ],
      ),
    );
  }
}
