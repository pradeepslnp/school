import 'package:flutter/foundation.dart';

import '../../../../core/domain.dart';

/// One scheduled leg of a child's day — the morning pickup or the afternoon drop.
///
/// [JourneyDirection] lives in `core/domain.dart` — shared with journey history.
///
/// Kept separate from the live [ChildDetail] fields above it: a leg describes a plan and
/// what happened on it, not a live position. A child can be at rest with a fully described
/// morning leg behind them and an afternoon leg still ahead.
@immutable
class JourneyLeg {
  const JourneyLeg({
    required this.direction,
    required this.state,
    this.vehicleDisplayName,
    this.stopName,
    this.scheduledAt,
    this.eventAt,
  });

  final JourneyDirection direction;
  final JourneyState state;
  final String? vehicleDisplayName;
  final String? stopName;

  /// When this leg is due to start.
  final SchoolTime? scheduledAt;

  /// When the most recent event on this leg happened — boarding, arrival, or handover.
  final SchoolTime? eventAt;
}

/// The full picture for one child — P-03. A superset of the dashboard card: the same
/// current state, plus the day's two legs, so a parent who taps through gets more than
/// they already saw on P-02, not a repeat of it.
@immutable
class ChildDetail {
  const ChildDetail({
    required this.studentId,
    required this.displayName,
    required this.currentState,
    this.className,
    this.tripId,
    this.vehicleDisplayName,
    this.stopName,
    this.lastEventAt,
    this.estimatedArrival,
    this.nextDepartureAt,
    this.positionFreshness,
    this.isPositionStaleReported,
    this.legs = const <JourneyLeg>[],
  });

  final String studentId;
  final String displayName;
  final String? className;
  final JourneyState currentState;

  /// The active trip carrying this child. Null unless [canTrack] is true. See
  /// `ChildStatus.tripId` in the dashboard feature for why this is a proposed field.
  final String? tripId;
  final String? vehicleDisplayName;
  final String? stopName;
  final SchoolTime? lastEventAt;

  /// Always presented as an estimate with its calculation time (BR-TRACK-006).
  final SchoolTime? estimatedArrival;
  final SchoolTime? nextDepartureAt;
  final Duration? positionFreshness;
  final bool? isPositionStaleReported;
  final List<JourneyLeg> legs;

  /// Stale data is never shown as current (BR-TRACK-003) — see [ChildStatus.isPositionStale]
  /// in the dashboard feature, which applies the identical rule.
  bool get isPositionStale =>
      isPositionStaleReported ??
      (positionFreshness == null ||
          positionFreshness! > const Duration(seconds: 30));

  /// Tracking is trip-scoped (BR-TRACK-001) — available only while a trip is actually under
  /// way for this child.
  bool get canTrack =>
      currentState == JourneyState.onBoard ||
      currentState == JourneyState.awaitingBoarding;
}
