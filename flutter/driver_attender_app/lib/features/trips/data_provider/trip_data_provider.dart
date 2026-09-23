import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for the crew's day (MOD-08).
///
/// Speaks endpoints and JSON only; what a failure *means* is [TripRepository]'s job.
///
/// Contract: documentation/04-api/TRIPS_BOARDING_API.md §Trips.
class TripDataProvider {
  TripDataProvider({required this.client});

  final RestClient client;

  /// `GET /trips/mine` — the runs this crew member is rostered for today.
  ///
  /// Sends no identifier of any kind. An endpoint that accepted a staff id would be an endpoint
  /// that could be asked about somebody else's day.
  Future<ApiResponse> fetchMyTrips() => client.get('/trips/mine');

  /// `POST /trips/{id}/start` (`PERM-TRIP-START`).
  ///
  /// Not retried, and given no idempotency key — a retried start is refused by the server's own
  /// guarded transition rather than silently repeated, which is the safer failure: the crew is
  /// told the run is already under way instead of being shown a second start that did nothing.
  ///
  /// [deviceStartedAt] is this handset's clock. The server records its own time as the fact and
  /// keeps this beside it (BR-TRIP-008) — a phone with a wrong clock must not be able to move a
  /// safety record in time.
  Future<ApiResponse> startTrip({
    required String tripId,
    required String vehicleId,
    required DateTime deviceStartedAt,
  }) {
    return client.post(
      '/trips/$tripId/start',
      body: {
        'vehicleId': vehicleId,
        'deviceStartedAt': deviceStartedAt.toUtc().toIso8601String(),
      },
    );
  }

  /// `POST /trips/{id}/end` (`PERM-TRIP-END`) — the crew has finished driving.
  ///
  /// This is not "closed": closing additionally asserts every child is accounted for, which needs
  /// trip-close reconciliation and is not built.
  Future<ApiResponse> endTrip({required String tripId}) =>
      client.post('/trips/$tripId/end');
}
