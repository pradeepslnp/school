import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import '../domain/trip_models.dart';

/// One run, and the single action it currently allows.
///
/// Big text and one full-width button, because this is read through a windscreen at 06:30 by
/// someone about to drive (DRIVER_ATTENDANT_APP.md). There is never more than one action on a
/// card: a driver choosing between two buttons at a kerb is a driver who can pick the wrong one.
class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.isSubmitting,
    required this.onStart,
    required this.onEnd,
  });

  final CrewTrip trip;
  final bool isSubmitting;
  final void Function(String vehicleId) onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: DriverSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(DriverSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${trip.routeCode} · ${_directionLabel(context)}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (trip.scheduledStartTime != null)
                  Text(trip.scheduledStartTime!, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: DriverSpacing.xs),
            Text(trip.routeName, style: theme.textTheme.bodyLarge),
            const SizedBox(height: DriverSpacing.sm),
            _StatusLine(trip: trip),
            const SizedBox(height: DriverSpacing.md),
            _action(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, AppLocalizations l10n) {
    if (isSubmitting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DriverSpacing.sm),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (trip.isStartable) {
      // The button names the bus. A driver confirming "Bus 12 · KA 05 MJ 1234" against the
      // vehicle in front of them is making the choice BR-TRIP-004 asks for; a bare "Start"
      // would be a tap with nothing verified behind it.
      return FilledButton(
        key: Key('trip_start_${trip.id}'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kDriverTouchTarget + 16),
        ),
        onPressed: () => onStart(trip.expectedVehicleId!),
        child: Text(
          l10n.dutyStartTripWithVehicle(
            trip.expectedVehicleDisplayName ?? '',
            trip.expectedVehicleRegistrationNo ?? '',
          ),
        ),
      );
    }

    if (trip.needsVehicleFromOffice) {
      return _Notice(
        icon: Icons.report_problem_outlined,
        text: l10n.dutyNoVehicleOnRoute,
        tone: Theme.of(context).colorScheme.error,
      );
    }

    if (trip.status.canEnd) {
      return FilledButton.tonal(
        key: Key('trip_end_${trip.id}'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kDriverTouchTarget + 16),
        ),
        onPressed: onEnd,
        child: Text(l10n.dutyEndTrip),
      );
    }

    return _Notice(
      icon: Icons.check_circle_outline,
      text: trip.status == TripStatus.cancelled
          ? l10n.dutyTripCancelled(trip.cancelledReason ?? '')
          : l10n.dutyTripFinished,
      tone: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  String _directionLabel(BuildContext context) => switch (trip.direction) {
        TripDirection.pickup => context.l10n.dutyDirectionPickup,
        TripDirection.drop => context.l10n.dutyDirectionDrop,
        TripDirection.unknown => context.l10n.dutyDirectionUnknown,
      };
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.trip});

  final CrewTrip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final label = switch (trip.status) {
      TripStatus.scheduled => l10n.dutyStatusScheduled,
      TripStatus.inProgress => l10n.dutyStatusInProgress,
      TripStatus.completed => l10n.dutyStatusCompleted,
      TripStatus.closed => l10n.dutyStatusClosed,
      TripStatus.cancelled => l10n.dutyStatusCancelled,
      TripStatus.unknown => l10n.dutyStatusUnknown,
    };

    return Row(
      children: [
        Chip(label: Text(label), visualDensity: VisualDensity.compact),
        const SizedBox(width: DriverSpacing.sm),
        if (trip.stopCount != null)
          Text(
            l10n.dutyStopCount(trip.stopCount!),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: tone),
        const SizedBox(width: DriverSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tone),
          ),
        ),
      ],
    );
  }
}
