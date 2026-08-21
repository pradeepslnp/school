import 'package:flutter/material.dart';

import '../app/app_size_constants.dart';
import '../app/theme.dart';

/// Shows how current live data is.
///
/// **Mandatory wherever live data appears** (BR-TRACK-003). Never show stale data as
/// current: a parent who leaves the house on a stale position and misses the bus is a
/// product failure, and one that destroys trust in everything else the app says.
///
/// Shared across every feature with live data — the dashboard, child detail, and the live
/// trip map — rather than owned by one of them
/// (docs/06-development/PROJECT_STRUCTURE.md).
///
/// Colour is never the only signal — each state carries an icon and a text label
/// (docs/05-ui/ACCESSIBILITY.md).
class FreshnessIndicator extends StatelessWidget {
  const FreshnessIndicator({
    super.key,
    required this.age,
    this.isStale,
    this.staleThreshold = const Duration(seconds: 30),
    this.lostThreshold = const Duration(minutes: 5),
  });

  /// How long ago the underlying data was reported. Null means nothing has been received.
  final Duration? age;

  /// The server's staleness verdict, where it gave one (BR-TRACK-003).
  ///
  /// Overrides the [age] comparison in one direction only: it can downgrade a position that
  /// looks fresh, never promote one that looks stale. Staleness is a safety signal, and a
  /// disagreement between two sources is resolved towards caution.
  final bool? isStale;

  final Duration staleThreshold;
  final Duration lostThreshold;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _describe(context.status);

    return Semantics(
      // Polite, not assertive: freshness ticking over must not interrupt a screen reader
      // mid-sentence. Assertive is reserved for the critical banner
      // (docs/05-ui/ACCESSIBILITY.md).
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizeConstants.iconXs, color: color),
          const SizedBox(width: GuardianSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: context.texts.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _describe(GuardianStatusColors status) {
    final current = age;

    if (current == null || current > lostThreshold) {
      return (
        Icons.circle_outlined,
        status.neutral,
        current == null ? 'No signal' : 'No signal for ${_humanise(current)}',
      );
    }

    if (current > staleThreshold || isStale == true) {
      return (
        Icons.access_time,
        status.warning,
        'Last seen ${_humanise(current)} ago',
      );
    }

    return (
      Icons.circle,
      status.safe,
      'Live · updated ${_humanise(current)} ago',
    );
  }

  static String _humanise(Duration duration) {
    if (duration.inMinutes < 1) return '${duration.inSeconds}s';
    if (duration.inHours < 1) return '${duration.inMinutes} min';
    return '${duration.inHours} h';
  }
}
