import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/child_detail_data_provider.dart';
import 'models/child_detail.dart';

/// Turns child-detail transport into domain meaning.
///
/// The BLoC depends on this, never on [ChildDetailDataProvider]
/// (ENGINEERING_PRINCIPLES.md §4). **This file is the only place that knows the JSON** — see
/// [ChildDetailDataProvider] for the contract it parses.
class ChildDetailRepository {
  ChildDetailRepository({required this.dataProvider});

  final ChildDetailDataProvider dataProvider;

  Future<Result<ChildDetail>> fetchDetail({required String studentId}) async {
    final response = await dataProvider.fetchDetail(studentId: studentId);
    if (!response.isSuccess) return _toFailure<ChildDetail>(response);

    final zone = _SchoolZone.parse(response.body);
    final resource = response.data;
    final attributes = resource['attributes'] as Map<String, Object?>? ?? const {};
    final displayName = attributes['displayName'] as String?;
    if (displayName == null || displayName.isEmpty) {
      // A 2xx this layer cannot read is a contract breach, not "no data" — see
      // HomeRepository for the same distinction.
      return const Failure<ChildDetail>(ErrorCode.internalError);
    }

    final journey = attributes['journey'] as Map<String, Object?>? ?? const {};
    final positionReceivedAt = _utc(journey['positionReceivedAt']);
    final serverNow = _utc((response.body['meta']
        as Map<String, Object?>?)?['timestamp']);

    final legs = (attributes['legs'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map((raw) => _parseLeg(raw, zone))
        .whereType<JourneyLeg>()
        .toList(growable: false);

    return Success<ChildDetail>(
      ChildDetail(
        studentId: (resource['id'] as String?) ?? studentId,
        displayName: displayName,
        className: attributes['className'] as String?,
        currentState: _parseState(journey['state'] as String?),
        tripId: journey['tripId'] as String?,
        vehicleDisplayName: journey['vehicleDisplayName'] as String?,
        stopName: journey['stopName'] as String?,
        lastEventAt: zone.at(_utc(journey['lastEventAt'])),
        estimatedArrival: zone.at(_utc(journey['estimatedArrival'])),
        nextDepartureAt: zone.at(_utc(journey['nextDepartureAt'])),
        positionFreshness: _age(from: positionReceivedAt, to: serverNow),
        isPositionStaleReported: journey['isPositionStale'] as bool?,
        legs: legs,
      ),
    );
  }

  static JourneyLeg? _parseLeg(Map<String, Object?> raw, _SchoolZone zone) {
    final direction = switch (raw['direction'] as String?) {
      'MORNING' => JourneyDirection.morning,
      'AFTERNOON' => JourneyDirection.afternoon,
      _ => null,
    };
    if (direction == null) return null;

    return JourneyLeg(
      direction: direction,
      state: _parseState(raw['state'] as String?),
      vehicleDisplayName: raw['vehicleDisplayName'] as String?,
      stopName: raw['stopName'] as String?,
      scheduledAt: zone.at(_utc(raw['scheduledAt'])),
      eventAt: zone.at(_utc(raw['eventAt'])),
    );
  }

  /// `SCREAMING_SNAKE_CASE` on the wire — identical vocabulary to HomeRepository, since
  /// this is the same [JourneyState] (docs/04-api/API_STANDARDS.md).
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

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return const Failure(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
    );
  }

  static DateTime? _utc(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static Duration? _age({DateTime? from, DateTime? to}) {
    if (from == null || to == null) return null;
    final age = to.difference(from);
    return age.isNegative ? Duration.zero : age;
  }
}

/// The school's clock, read once from the response envelope — identical rule to
/// HomeRepository's `_SchoolZone` (BR-CFG-006). Duplicated rather than shared because it is
/// six lines of envelope parsing, not a business rule; see [ChildDetailRepository] docs for
/// why [JourneyState] itself *is* shared.
class _SchoolZone {
  const _SchoolZone({required this.timezoneId, required this.offset});

  final String timezoneId;
  final Duration offset;

  static _SchoolZone parse(Map<String, Object?> body) {
    final meta = body['meta'] as Map<String, Object?>? ?? const {};
    final school = meta['school'] as Map<String, Object?>? ?? const {};
    final minutes = school['utcOffsetMinutes'];

    return _SchoolZone(
      timezoneId: school['timezoneId'] as String? ?? 'UTC',
      offset: minutes is num ? Duration(minutes: minutes.round()) : Duration.zero,
    );
  }

  SchoolTime? at(DateTime? utc) =>
      utc == null ? null : SchoolTime.fromUtc(utc, timezoneId: timezoneId, offset: offset);
}
