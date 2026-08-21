import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/live_trip_data_provider.dart';
import 'models/live_trip.dart';

/// Turns live-trip transport into domain meaning.
///
/// The BLoC depends on this, never on [LiveTripDataProvider] (ENGINEERING_PRINCIPLES.md §4).
class LiveTripRepository {
  LiveTripRepository({required this.dataProvider});

  final LiveTripDataProvider dataProvider;

  /// [vehicleDisplayName] and [stopName] are supplied by the caller rather than read from
  /// either endpoint: neither `GET /trips/{id}/position` nor `GET /trips/{id}/eta`
  /// (docs/04-api/TRACKING_NOTIFICATION_API.md) carries them, and the screen that opens this
  /// one — the dashboard card or child detail — already has them from `journey`.
  Future<Result<LiveTrip>> fetchLiveTrip({
    required String tripId,
    required String vehicleDisplayName,
    required String stopName,
  }) async {
    final results = await Future.wait([
      dataProvider.fetchPosition(tripId: tripId),
      dataProvider.fetchEta(tripId: tripId),
    ]);
    final position = results[0];
    final eta = results[1];

    // Either call answering "not while this trip is inactive" is the same fact told twice;
    // one failure is enough to explain the whole screen (docs/05-ui/PARENT_APP.md).
    if (!position.isSuccess) return _toFailure<LiveTrip>(position);
    if (!eta.isSuccess) return _toFailure<LiveTrip>(eta);

    final now = DateTime.now().toUtc();
    final positionData = position.data;
    final receivedAt = _utc(positionData['receivedAt']);

    // `eta.data['stops']` is a list nested under `data`, not `data` itself — read it
    // directly rather than through `dataList`, which expects the list at the top level.
    final stops = (eta.data['stops'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>();
    final firstStop = stops.isEmpty ? null : stops.first;

    final estimatedArrival = _utc(firstStop?['estimatedArrival']);
    final calculatedAt = _utc(firstStop?['calculatedAt']);

    return Success<LiveTrip>(
      LiveTrip(
        tripId: tripId,
        vehicleDisplayName: vehicleDisplayName,
        stopName: stopName,
        headingDeg: (positionData['headingDeg'] as num?)?.toDouble(),
        positionFreshness: _age(from: receivedAt, to: now),
        isPositionStaleReported: positionData['isStale'] as bool?,
        stopsAway: firstStop?['stopsAway'] as int?,
        etaInMinutes: estimatedArrival == null
            ? null
            : estimatedArrival.difference(now).inMinutes.clamp(0, 999).toInt(),
        etaCalculatedAgo: _age(from: calculatedAt, to: now),
        confidence: _parseConfidence(firstStop?['confidence'] as String?),
      ),
    );
  }

  static EtaConfidence _parseConfidence(String? wire) {
    return switch (wire) {
      'HIGH' => EtaConfidence.high,
      'MEDIUM' => EtaConfidence.medium,
      'LOW' => EtaConfidence.low,
      _ => EtaConfidence.unknown,
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
