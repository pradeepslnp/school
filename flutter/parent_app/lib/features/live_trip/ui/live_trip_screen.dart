import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../utils/utils.dart';
import '../../../widgets/freshness_indicator.dart';
import '../repository/models/live_trip.dart';
import '../widgets/vehicle_map_surface.dart';

/// P-04 — the live trip map.
///
/// Renders state it is given; it does not fetch or poll (ENGINEERING_PRINCIPLES.md §8).
/// Reached only by tapping *Track*, never the default view (docs/05-ui/PARENT_APP.md).
class LiveTripScreen extends StatelessWidget {
  const LiveTripScreen({
    super.key,
    this.trip,
    this.isLoading = false,
    this.isOutsideTrip = false,
    this.loadFailure,
    this.onRefresh,
  });

  final LiveTrip? trip;
  final bool isLoading;

  /// True when tracking is unavailable because no trip is active right now (BR-TRACK-001).
  final bool isOutsideTrip;

  final String? loadFailure;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live trip')),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    // Bound once up front: a public field cannot be type-promoted, so the null checks
    // below only narrow to non-null LiveTrip through this local.
    final trip = this.trip;

    if (isLoading && trip == null && !isOutsideTrip) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isOutsideTrip) {
      return const _Explanation(
        icon: Icons.map_outlined,
        title: 'Tracking is not available right now',
        detail: 'Live tracking only runs while the bus is on a trip '
            '(docs/05-ui/PARENT_APP.md, BR-TRACK-001). '
            'Check back once the trip has started.',
      );
    }

    if (loadFailure != null && trip == null) {
      return _Explanation(
        icon: Icons.cloud_off,
        title: 'Cannot load this trip right now',
        detail: loadFailure!,
        onRetry: onRefresh,
      );
    }

    if (trip == null) {
      return const _Explanation(
        icon: Icons.map_outlined,
        title: 'No trip to show',
        detail: 'This child has no active trip right now.',
      );
    }

    final content = ReadableWidth(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(GuardianSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The text summary, always present and always understandable without the map
            // below it (docs/05-ui/PARENT_APP.md, docs/05-ui/ACCESSIBILITY.md).
            Text(_summary(trip), style: context.texts.titleLarge),
            const SizedBox(height: GuardianSpacing.xs),
            FreshnessIndicator(
              age: trip.positionFreshness,
              isStale: trip.isPositionStaleReported,
            ),
            const SizedBox(height: GuardianSpacing.md),
            VehicleMapSurface(headingDeg: trip.headingDeg),
            const SizedBox(height: GuardianSpacing.md),
            Text(
              _etaCaption(trip),
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    if (onRefresh == null) return content;
    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }

  String _summary(LiveTrip trip) {
    final stops = trip.stopsAway;
    final eta = trip.etaInMinutes;
    return [
      trip.vehicleDisplayName,
      if (stops != null) '$stops stop${stops == 1 ? '' : 's'} away',
      if (eta != null) '~$eta min to ${trip.stopName}',
    ].join(' · ');
  }

  String _etaCaption(LiveTrip trip) {
    final confidence = switch (trip.confidence) {
      EtaConfidence.high => null,
      EtaConfidence.medium => ' · moderate confidence',
      EtaConfidence.low => ' · low confidence — routing unavailable',
      EtaConfidence.unknown => null,
    };
    final agoSeconds = trip.etaCalculatedAgo?.inSeconds;
    final ago = agoSeconds == null
        ? 'just now'
        : agoSeconds < 60
            ? '${agoSeconds}s ago'
            : '${trip.etaCalculatedAgo!.inMinutes} min ago';
    // Always states when the estimate was made, never just the estimate itself
    // (BR-TRACK-006).
    return 'Estimate calculated $ago${confidence ?? ''}.';
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GuardianSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizeConstants.emptyStateIcon, color: context.colors.onSurfaceVariant),
            const SizedBox(height: GuardianSpacing.md),
            Text(title, style: context.texts.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: GuardianSpacing.sm),
            Text(
              detail,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: GuardianSpacing.lg),
              FilledButton.tonal(
                onPressed: () => onRetry!(),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
