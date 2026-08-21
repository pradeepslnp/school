import 'package:flutter/foundation.dart';

import '../../../../core/domain.dart';

/// A child's current transport status, as shown on the parent home screen.
///
/// [JourneyState] itself lives in `core/domain.dart` — it is shared with child detail, the
/// live map, and journey history, not owned by the dashboard.
@immutable
class ChildStatus {
  const ChildStatus({
    required this.studentId,
    required this.displayName,
    required this.journeyState,
    this.className,
    this.tripId,
    this.vehicleDisplayName,
    this.stopName,
    this.lastEventAt,
    this.estimatedArrival,
    this.nextDepartureAt,
    this.positionFreshness,
    this.isPositionStaleReported,
  });

  final String studentId;
  final String displayName;
  final String? className;
  final JourneyState journeyState;

  /// The active trip carrying this child, when there is one.
  ///
  /// Needed to open P-04 (`GET /trips/{id}/position`, docs/04-api/TRACKING_NOTIFICATION_API.md)
  /// — a proposed addition to `journey` alongside the fields already documented in
  /// docs/04-api/STUDENTS_GUARDIANS_API.md, since the dashboard has nowhere else to learn
  /// which trip to track. Null whenever [canTrack] is false.
  final String? tripId;

  /// What the parent calls the vehicle — "Bus 12", never a registration number.
  final String? vehicleDisplayName;

  final String? stopName;

  /// When the last boarding or handover event occurred, in the school's timezone
  /// (BR-CFG-006).
  final SchoolTime? lastEventAt;

  /// Always presented as an estimate with its calculation time (BR-TRACK-006).
  final SchoolTime? estimatedArrival;

  /// When the child's next scheduled bus leaves, if there is one later today.
  ///
  /// What keeps the card calm rather than empty between trips (docs/05-ui/PARENT_APP.md):
  /// "At school · afternoon bus 15:10" tells a parent that nothing is wrong, where a blank
  /// card leaves them wondering whether the app simply failed to load.
  final SchoolTime? nextDepartureAt;

  /// How stale the underlying position is. Null when no live tracking applies.
  final Duration? positionFreshness;

  /// The server's own staleness verdict, where it gave one.
  ///
  /// The API always returns `isStale` (BR-TRACK-003) and it is authoritative: the server
  /// knows about ingestion lag and rejected reports that an age computed from timestamps
  /// cannot see. Held separately from [positionFreshness] rather than folded into it,
  /// because inventing an age to force the display to agree would put a number on screen
  /// that nothing measured.
  final bool? isPositionStaleReported;

  /// Whether live position should be shown as current.
  ///
  /// Stale data is never displayed as current (BR-TRACK-003) — a parent who leaves the
  /// house on a stale position and misses the bus is a product failure.
  ///
  /// The server's verdict wins where there is one; otherwise the age decides, and an
  /// absent age counts as stale rather than fresh.
  bool get isPositionStale =>
      isPositionStaleReported ??
      (positionFreshness == null ||
          positionFreshness! > const Duration(seconds: 30));

  /// Whether live tracking is available for this child right now.
  ///
  /// Tracking is trip-scoped (BR-TRACK-001): vehicles are not tracked outside trips, which
  /// is what keeps the platform a safety tool rather than staff surveillance.
  bool get canTrack => journeyState == JourneyState.onBoard ||
      journeyState == JourneyState.awaitingBoarding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildStatus &&
          other.studentId == studentId &&
          other.journeyState == journeyState &&
          other.lastEventAt == lastEventAt);

  @override
  int get hashCode => Object.hash(studentId, journeyState, lastEventAt);
}
