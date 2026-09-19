import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
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

  /// Stops added here live only in this dialog until *Save*. Closing — the button, Escape, or a
  /// click outside — must not throw them away silently, which is how a route ends up with no
  /// stops and nobody knowing why.
  Future<void> _confirmDiscard(BuildContext context) async {
    final navigator = Navigator.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: Text(context.l10n.routeStopsDiscardTitle),
        content: Text(context.l10n.routeStopsDiscardBody),
        actions: [
          TextButton(
            key: const Key('route_stops_keep_editing_button'),
            onPressed: () => Navigator.of(confirmContext).pop(false),
            child: Text(context.l10n.routeStopsKeepEditingButton),
          ),
          FilledButton(
            key: const Key('route_stops_discard_button'),
            onPressed: () => Navigator.of(confirmContext).pop(true),
            child: Text(context.l10n.routeStopsDiscardButton),
          ),
        ],
      ),
    );
    if (discard ?? false) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<RouteStopsBloc, RouteStopsState>(
      // Say so when the save lands — the list looks the same before and after, and an operator
      // who cannot tell whether it worked closes the dialog guessing.
      listenWhen: (previous, current) =>
          previous.isSaving && !current.isSaving && current.error == null,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.routeStopsSavedSnackbar))),
      child: _guarded(context, theme),
    );
  }

  Widget _guarded(BuildContext context, ThemeData theme) {
    return BlocBuilder<RouteStopsBloc, RouteStopsState>(
      buildWhen: (previous, current) => previous.isDirty != current.isDirty,
      builder: (context, dirtyState) => PopScope(
        canPop: !dirtyState.isDirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard(context);
        },
        child: _dialog(context, theme),
      ),
    );
  }

  Widget _dialog(BuildContext context, ThemeData theme) {
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
                        Text(context.l10n.routeStopsDialogTitle, style: theme.textTheme.titleLarge),
                        Text(
                          context.l10n.assignRouteNameAndCode(route.name, route.code),
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
                      label: Text(context.l10n.commonSaveButton),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.md),
              Expanded(
                child: BlocBuilder<RouteStopsBloc, RouteStopsState>(
                  builder: (context, state) {
                    if (state.isLoading && state.stops.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: context.l10n.routeStopsLoadingLabel,
                        ),
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
                        if (state.isDirty && state.stops.length >= 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                            child: Text(
                              context.l10n.routeStopsUnsavedHint,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.status.warning,
                              ),
                            ),
                          ),
                        if (state.stops.length < 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                            child: Text(
                              context.l10n.routeStopsMinWarning,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.status.warning,
                              ),
                            ),
                          ),
                        Expanded(
                          child: state.stops.isEmpty
                              ? Center(
                                  child: Text(
                                    context.l10n.routeStopsEmptyState,
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
                      label: Text(context.l10n.routeStopsAddButton),
                    ),
                  ),
                  const SizedBox(width: AdminSpacing.md),
                  Expanded(
                    child: TextButton(
                      key: const Key('route_stops_close_button'),
                      // maybePop, not pop: goes through the PopScope above, so unsaved stops
                      // are confirmed before they are discarded.
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(context.l10n.commonCloseButton),
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
    final l10n = context.l10n;
    final times = [
      if (stop.scheduledPickupTime != null) l10n.stopPickupTime(stop.scheduledPickupTime!),
      if (stop.scheduledDropTime != null) l10n.stopDropTime(stop.scheduledDropTime!),
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text(stop.name),
      subtitle: Text(
        [
          '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
          l10n.stopGeofenceRadiusMetres(stop.geofenceRadiusM),
          if (times.isNotEmpty) times,
          if (stop.landmark != null) stop.landmark!,
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        key: Key('route_stops_remove_$index'),
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.routeStopsRemoveTooltip(stop.name),
        onPressed: onRemove,
      ),
    );
  }
}
