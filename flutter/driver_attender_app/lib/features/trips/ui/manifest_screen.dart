import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../sync/widgets/live_sync_status_banner.dart';
import '../bloc/manifest_bloc.dart';
import '../bloc/manifest_event.dart';
import '../bloc/manifest_state.dart';
import '../domain/manifest_models.dart';
import '../domain/trip_models.dart';
import '../widgets/manifest_child_tile.dart';

/// The children on one run, and the one action each of them currently allows (BRD-001..004).
///
/// Designed for a moving bus and a gloved thumb: one row per child, one full-width action, no
/// nested menus. The counter in the app bar is the number still aboard, because that is the
/// question a crew asks at the end of a route and the one BR-SAFE-001 turns on.
class ManifestScreen extends StatefulWidget {
  const ManifestScreen({super.key, required this.trip});

  final CrewTrip trip;

  @override
  State<ManifestScreen> createState() => _ManifestScreenState();
}

class _ManifestScreenState extends State<ManifestScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ManifestBloc>().add(const ManifestRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ManifestBloc, ManifestState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.trip.routeCode} · ${widget.trip.routeName}'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(bottom: DriverSpacing.sm),
                child: Text(
                  l10n.manifestAboardCount(
                    state.stillAboardCount.toString(),
                    state.expectedCount.toString(),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              const LiveSyncStatusBanner(),
              Expanded(child: _body(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ManifestState state) {
    if (state.isLoading && !state.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasLoaded && state.error != null) {
      return _ManifestError(state: state);
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<ManifestBloc>().add(const ManifestRequested()),
      child: ListView.builder(
        padding: const EdgeInsets.all(DriverSpacing.md),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.children.length,
        itemBuilder: (context, index) {
          final child = state.children[index];
          return ManifestChildTile(
            child: child,
            onBoard: () => context
                .read<ManifestBloc>()
                .add(BoardingRecorded(studentId: child.studentId, isBoarding: true)),
            onAlight: () => _confirmAlight(context, child),
          );
        },
      ),
    );
  }

  /// Getting a child *off* the bus is the irreversible half of the journey, so it is the one that
  /// asks. Boarding is a single tap: a child stepping on is easy to correct and hard to get
  /// wrong, while an alight recorded for the wrong child leaves a real one aboard with the
  /// platform believing they are home (BR-SAFE-001).
  Future<void> _confirmAlight(BuildContext context, ManifestChild child) async {
    final bloc = context.read<ManifestBloc>();
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manifestConfirmAlightTitle(child.studentName)),
        content: Text(
          child.expectedStopName == null
              ? l10n.manifestConfirmAlightBody
              : l10n.manifestConfirmAlightAtStop(child.expectedStopName!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.manifestConfirmAlightConfirm),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(BoardingRecorded(studentId: child.studentId, isBoarding: false));
    }
  }
}

class _ManifestError extends StatelessWidget {
  const _ManifestError({required this.state});

  final ManifestState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DriverSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: DriverSpacing.md),
            Text(
              context.l10n.manifestUnavailable,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
