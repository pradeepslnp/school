import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for P-04, the live trip map.
///
/// Contract: `GET /trips/{id}/position` and `GET /trips/{id}/eta`
/// (docs/04-api/TRACKING_NOTIFICATION_API.md). Two calls, not a combined one — both
/// endpoints are independently documented and independently cacheable server-side (position
/// from Redis, ETA computed), and this screen already needs to poll position far more often
/// than it needs a fresh ETA.
///
/// Available **only while the trip is active** (BR-TRACK-001) → the documented `422
/// TRACKING_NOT_AVAILABLE_OUTSIDE_TRIP`, which the dummy fixture below reproduces for any
/// trip id other than the one the dashboard fixture marks as in progress.
///
/// **Dummy transport.** This build of work is scoped to the Flutter client only
/// (`guardian-docs/INSTRUCTIONS.md`). Both methods return fixtures in the documented shape
/// instead of calling [client]; [client] is held so a live backend is wired in by changing
/// only these two method bodies.
class LiveTripDataProvider {
  LiveTripDataProvider({required this.client});

  final RestClient client;

  /// The one trip the dummy backend treats as active — matches the `tripId` in
  /// `HomeDataProvider`'s and `ChildDetailDataProvider`'s fixtures.
  static const _activeTripId = '770e8400-e29b-41d4-a716-446655440010';

  Future<ApiResponse> fetchPosition({required String tripId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (tripId != _activeTripId) return _outsideTripFailure;

    final now = DateTime.now().toUtc();
    return ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          'latitude': 28.5601 + _jitter(now),
          'longitude': 77.2065 + _jitter(now),
          'speedMps': 8.3,
          'headingDeg': 145,
          'deviceTime': now.subtract(const Duration(seconds: 4)).toIso8601String(),
          'receivedAt': now.subtract(const Duration(seconds: 2)).toIso8601String(),
          'isStale': false,
          'staleSinceSeconds': 0,
        },
      },
    );
  }

  Future<ApiResponse> fetchEta({required String tripId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (tripId != _activeTripId) return _outsideTripFailure;

    final now = DateTime.now().toUtc();
    return ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          'stops': [
            {
              'stopId': 'stop-green-park',
              'stopName': 'Green Park',
              'stopsAway': 3,
              'estimatedArrival': now.add(const Duration(minutes: 7)).toIso8601String(),
              'calculatedAt': now.toIso8601String(),
              'confidence': 'HIGH',
            },
          ],
        },
      },
    );
  }

  /// A little motion each time this is called, so "Live" reads as live during a demo rather
  /// than a frozen fixture — the position otherwise never changes between polls.
  double _jitter(DateTime now) =>
      (now.second % 10) * 0.0003;

  static final ApiResponse _outsideTripFailure = ApiResponse(
    statusCode: 422,
    body: const {
      'error': {
        'code': 'TRACKING_NOT_AVAILABLE_OUTSIDE_TRIP',
        'messageKey': 'error.tracking.not_available_outside_trip',
        'message': 'This trip is not currently in progress.',
        'businessRule': 'BR-TRACK-001',
      },
    },
  );
}
