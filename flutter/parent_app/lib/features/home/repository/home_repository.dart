import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/home_data_provider.dart';
import 'models/child_status.dart';
import 'models/children_snapshot.dart';

/// Turns dashboard transport into domain meaning.
///
/// The BLoC depends on this, never on [HomeDataProvider] — so the BLoC can be tested with a
/// fake repository and no HTTP at all, and a wire-format change never reaches presentation
/// (ENGINEERING_PRINCIPLES.md §4).
///
/// **This file is the only place that knows the JSON.** When the contract below is settled
/// against the real backend, this is the one file that changes.
///
/// Contract: docs/04-api/STUDENTS_GUARDIANS_API.md — `GET /guardians/me/students`.
class HomeRepository {
  HomeRepository({required this.dataProvider});

  final HomeDataProvider dataProvider;

  /// Every child the calling guardian may see, and where each one is now.
  ///
  /// Returns a [Result]; nothing throws for an expected failure. No network is an ordinary
  /// outcome for this app, not an exception.
  Future<Result<ChildrenSnapshot>> fetchChildren() async {
    final response = await dataProvider.fetchChildren();
    if (!response.isSuccess) return _toFailure<ChildrenSnapshot>(response);

    final zone = _SchoolZone.parse(response.body);
    final observedAt = zone.at(_utc(_meta(response.body)['timestamp']));

    final children = <ChildStatus>[];
    for (final entry in response.dataList) {
      if (entry is! Map<String, Object?>) continue;
      final child = _parseChild(entry, zone, observedAt?.value);
      // A row that cannot be identified is dropped; a row whose *status* is unreadable is
      // kept and shown as unknown. The distinction matters: an unnamed card helps nobody,
      // but a silently missing child is the failure this app exists to prevent.
      if (child != null) children.add(child);
    }

    return Success<ChildrenSnapshot>(
      ChildrenSnapshot(children: children, observedAt: observedAt),
    );
  }

  /// Maps an unsuccessful response onto the shared error vocabulary.
  ///
  /// A transport failure carries no error code, so it is distinguished here rather than by
  /// catching exceptions — RestClient already converts socket, timeout, and malformed-reply
  /// faults into [ApiResponse.transportFailure], so every outcome arrives on one path.
  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return const Failure(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
    );
  }

  static Map<String, Object?> _meta(Map<String, Object?> body) =>
      body['meta'] as Map<String, Object?>? ?? const {};

  static ChildStatus? _parseChild(
    Map<String, Object?> entry,
    _SchoolZone zone,
    DateTime? serverNow,
  ) {
    final id = entry['id'] as String?;
    final attributes = entry['attributes'] as Map<String, Object?>? ?? const {};
    final displayName = attributes['displayName'] as String?;

    if (id == null || displayName == null || displayName.isEmpty) return null;

    final journey = attributes['journey'] as Map<String, Object?>? ?? const {};
    final positionReceivedAt = _utc(journey['positionReceivedAt']);

    return ChildStatus(
      studentId: id,
      displayName: displayName,
      className: attributes['className'] as String?,
      journeyState: _parseState(journey['state'] as String?),
      tripId: journey['tripId'] as String?,
      vehicleDisplayName: journey['vehicleDisplayName'] as String?,
      stopName: journey['stopName'] as String?,
      lastEventAt: zone.at(_utc(journey['lastEventAt'])),
      estimatedArrival: zone.at(_utc(journey['estimatedArrival'])),
      nextDepartureAt: zone.at(_utc(journey['nextDepartureAt'])),
      // Measured between two *server* timestamps. Deriving it from the device clock instead
      // would report a phone that is five minutes fast as a five-minute-stale bus.
      positionFreshness: _age(from: positionReceivedAt, to: serverNow),
      isPositionStaleReported: journey['isPositionStale'] as bool?,
    );
  }

  /// `SCREAMING_SNAKE_CASE` on the wire (docs/04-api/API_STANDARDS.md).
  ///
  /// An unrecognised value becomes [JourneyState.unknown] rather than a default, so a state
  /// added to the API after this build shipped is reported as unreadable instead of being
  /// quietly rendered as something reassuring.
  static JourneyState _parseState(String? wire) {
    return switch (wire) {
      'AT_REST' => JourneyState.atRest,
      'SCHEDULED' => JourneyState.scheduled,
      'AWAITING_BOARDING' => JourneyState.awaitingBoarding,
      'ON_BOARD' => JourneyState.onBoard,
      'ARRIVED_AT_SCHOOL' => JourneyState.arrivedAtSchool,
      'HANDED_OVER' => JourneyState.handedOver,
      'NO_SHOW' => JourneyState.noShow,
      'ABSENT' => JourneyState.absent,
      'UNACCOUNTED' => JourneyState.unaccounted,
      _ => JourneyState.unknown,
    };
  }

  static DateTime? _utc(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  /// How old [from] is relative to [to].
  ///
  /// Negative results are clamped to zero: a position stamped slightly ahead of the
  /// response is clock skew between two servers, and "updated -3s ago" reads as a bug.
  static Duration? _age({DateTime? from, DateTime? to}) {
    if (from == null || to == null) return null;
    final age = to.difference(from);
    return age.isNegative ? Duration.zero : age;
  }
}

/// The school's clock, read once from the response envelope.
///
/// All timestamps are UTC on the wire and clients render in the school's timezone
/// (BR-CFG-006, docs/04-api/API_STANDARDS.md). The offset comes from the server rather than
/// from a device timezone database, so a parent abroad and a parent at the gate convert
/// identically.
class _SchoolZone {
  const _SchoolZone({required this.timezoneId, required this.offset});

  final String timezoneId;
  final Duration offset;

  static _SchoolZone parse(Map<String, Object?> body) {
    final meta = body['meta'] as Map<String, Object?>? ?? const {};
    final school = meta['school'] as Map<String, Object?>? ?? const {};
    final minutes = school['utcOffsetMinutes'];

    return _SchoolZone(
      // Falling back to UTC rather than to the device zone. A wrong-but-labelled zone is
      // detectable; silently substituting the parent's own zone reproduces exactly the
      // travelling-parent bug BR-CFG-006 exists to prevent.
      timezoneId: school['timezoneId'] as String? ?? 'UTC',
      offset: minutes is num
          ? Duration(minutes: minutes.round())
          : Duration.zero,
    );
  }

  SchoolTime? at(DateTime? utc) => utc == null
      ? null
      : SchoolTime.fromUtc(utc, timezoneId: timezoneId, offset: offset);
}
