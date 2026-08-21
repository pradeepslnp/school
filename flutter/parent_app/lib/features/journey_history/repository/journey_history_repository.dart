import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/journey_history_data_provider.dart';
import 'models/journey_history_entry.dart';

/// Turns journey-history transport into domain meaning.
///
/// The BLoC depends on this, never on [JourneyHistoryDataProvider]
/// (ENGINEERING_PRINCIPLES.md §4). See that class for the contract this parses.
class JourneyHistoryRepository {
  JourneyHistoryRepository({required this.dataProvider});

  final JourneyHistoryDataProvider dataProvider;

  Future<Result<List<JourneyHistoryEntry>>> fetchHistory({
    required String studentId,
  }) async {
    final response = await dataProvider.fetchHistory(studentId: studentId);
    if (!response.isSuccess) return _toFailure<List<JourneyHistoryEntry>>(response);

    final zone = _SchoolZone.parse(response.body);

    final entries = response.dataList
        .whereType<Map<String, Object?>>()
        .map((raw) => _parseEntry(raw, zone))
        .whereType<JourneyHistoryEntry>()
        // Newest first — a parent scrolling back starts from "what happened most recently"
        // (docs/05-ui/PARENT_APP.md, P-08's "grouped by day, newest first" applies equally
        // here).
        .toList(growable: false)
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    return Success<List<JourneyHistoryEntry>>(entries);
  }

  static JourneyHistoryEntry? _parseEntry(
    Map<String, Object?> raw,
    _SchoolZone zone,
  ) {
    final serviceDate = DateTime.tryParse(raw['serviceDate'] as String? ?? '');
    if (serviceDate == null) return null;

    final direction = switch (raw['direction'] as String?) {
      'MORNING' => JourneyDirection.morning,
      'AFTERNOON' => JourneyDirection.afternoon,
      _ => null,
    };
    if (direction == null) return null;

    return JourneyHistoryEntry(
      serviceDate: serviceDate,
      direction: direction,
      state: _parseState(raw['state'] as String?),
      vehicleDisplayName: raw['vehicleDisplayName'] as String?,
      stopName: raw['stopName'] as String?,
      eventAt: zone.at(_utc(raw['eventAt'])),
    );
  }

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
}

/// The school's clock, read once from the response envelope (BR-CFG-006) — the same rule
/// applied identically in every feature that renders a server timestamp.
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
