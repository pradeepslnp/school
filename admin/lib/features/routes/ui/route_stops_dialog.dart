import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../bloc/route_stops_bloc.dart';
import '../bloc/route_stops_event.dart';
import '../bloc/route_stops_state.dart';
import '../domain/route_models.dart';
import '../domain/stop_models.dart';
import '../widgets/stop_form.dart';

/// The stops editor for one route (RTE-001, A-31 interim), reached from the Routes screen.
///
/// A route needs at least two stops before a student can be assigned to it, so this is the
/// prerequisite step for pickup/drop. Stops are edited as a working list and written all at once
/// on Save — the endpoint replaces the whole list, so partial edits never leave a sequence gap.
class RouteStopsDialog extends StatelessWidget {
  const RouteStopsDialog({super.key, required this.route});

  final CreatedRoute route;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<RouteStopsBloc>(
      create: (_) => RouteStopsBloc(repository: dependencies.stopRepository)
        ..add(RouteStopsRequested(routeId: route.id)),
      child: _RouteStopsView(route: route),
    );
  }
}

class _RouteStopsView extends StatelessWidget {
  const _RouteStopsView({required this.route});

  final CreatedRoute route;

  Future<void> _openAddStop(BuildContext context) async {
    final bloc = context.read<RouteStopsBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: StopForm(
              onCancel: () => Navigator.of(dialogContext).pop(),
              onAdd: (stop) {
                bloc.add(StopAppended(stop: stop));
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stops', style: theme.textTheme.titleLarge),
                        Text(
                          '${route.name} · ${route.code}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<RouteStopsBloc, RouteStopsState>(
                    builder: (context, state) => FilledButton.icon(
                      key: const Key('route_stops_save_button'),
                      onPressed: state.canSave
                          ? () => context
                              .read<RouteStopsBloc>()
                              .add(RouteStopsSaved(routeId: route.id))
                          : null,
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.md),
              Expanded(
                child: BlocBuilder<RouteStopsBloc, RouteStopsState>(
                  builder: (context, state) {
                    if (state.isLoading && state.stops.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(semanticsLabel: 'Loading stops'),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                            child: OnboardingErrorText(
                              code: state.error!,
                              messageKey: state.errorMessageKey,
                            ),
                          ),
                        if (state.stops.length < 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                            child: Text(
                              'A route needs at least two stops before students can be '
                              'assigned to it.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.status.warning,
                              ),
                            ),
                          ),
                        Expanded(
                          child: state.stops.isEmpty
                              ? Center(
                                  child: Text(
                                    'No stops yet. Add the first one.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  key: const Key('route_stops_list'),
                                  itemCount: state.stops.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) => _StopRow(
                                    index: index,
                                    stop: state.stops[index],
                                    onRemove: () => context
                                        .read<RouteStopsBloc>()
                                        .add(StopRemoved(index: index)),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AdminSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('route_stops_add_button'),
                      onPressed: () => _openAddStop(context),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add stop'),
                    ),
                  ),
                  const SizedBox(width: AdminSpacing.md),
                  Expanded(
                    child: TextButton(
                      key: const Key('route_stops_close_button'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.index, required this.stop, required this.onRemove});

  final int index;
  final RouteStop stop;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final times = [
      if (stop.scheduledPickupTime != null) 'pickup ${stop.scheduledPickupTime}',
      if (stop.scheduledDropTime != null) 'drop ${stop.scheduledDropTime}',
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text(stop.name),
      subtitle: Text(
        [
          '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
          '${stop.geofenceRadiusM} m',
          if (times.isNotEmpty) times,
          if (stop.landmark != null) stop.landmark!,
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        key: Key('route_stops_remove_$index'),
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Remove ${stop.name}',
        onPressed: onRemove,
      ),
    );
  }
}
