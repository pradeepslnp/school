import 'package:flutter/foundation.dart';

/// How much to trust an ETA (BR-TRACK-006). Drops to [low] when routing is unavailable and
/// a straight-line fallback was used — the parent app never states that silently.
enum EtaConfidence { high, medium, low, unknown }

/// P-04's live picture of one trip, from the guardian's child's point of view.
///
/// Deliberately narrow: no other student's stop, no full manifest, no vehicle registration
/// — only what BR-NTF-007 permits a guardian to see about a trip carrying their own child.
@immutable
class LiveTrip {
  const LiveTrip({
    required this.tripId,
    required this.vehicleDisplayName,
    required this.stopName,
    this.headingDeg,
    this.positionFreshness,
    this.isPositionStaleReported,
    this.stopsAway,
    this.etaInMinutes,
    this.etaCalculatedAgo,
    this.confidence = EtaConfidence.unknown,
  });

  final String tripId;
  final String vehicleDisplayName;

  /// The guardian's own stop — never another family's (BR-NTF-007 🔴).
  final String stopName;

  /// Compass heading of travel, for the vehicle marker.
  final double? headingDeg;

  final Duration? positionFreshness;
  final bool? isPositionStaleReported;

  /// How many stops remain before [stopName]. Null when the trip has not yet started moving.
  final int? stopsAway;

  /// Minutes until arrival at [stopName], relative to now.
  ///
  /// Kept relative rather than as an absolute time: neither `GET /trips/{id}/position` nor
  /// `GET /trips/{id}/eta` (docs/04-api/TRACKING_NOTIFICATION_API.md) carries the school's
  /// timezone offset the way `GET /guardians/me/students` does, and PARENT_APP.md's own
  /// worked example for this screen — *"~7 min to Green Park"* — is relative for exactly
  /// that reason.
  final int? etaInMinutes;

  /// How long ago the estimate was computed. Always shown alongside it (BR-TRACK-006) — an
  /// ETA is an estimate, not a promise, and one computed two minutes ago is worth less than
  /// one computed just now.
  final Duration? etaCalculatedAgo;
  final EtaConfidence confidence;

  bool get isPositionStale =>
      isPositionStaleReported ??
      (positionFreshness == null ||
          positionFreshness! > const Duration(seconds: 30));
}
