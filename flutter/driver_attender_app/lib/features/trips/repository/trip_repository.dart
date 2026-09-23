import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/trip_data_provider.dart';
import '../domain/trip_models.dart';

/// Decides what the crew's day means (MOD-08, TRP-002/004).
///
/// Depends on a data provider only. Nothing above this layer sees an HTTP status code.
class TripRepository {
  TripRepository({required this.dataProvider});

  final TripDataProvider dataProvider;

  Future<Result<List<CrewTrip>>> myTrips() async {
    final response = await dataProvider.fetchMyTrips();
    if (!response.isSuccess) return _toFailure<List<CrewTrip>>(response);

    final trips = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseTrip)
        .whereType<CrewTrip>()
        .toList(growable: false);
    return Success<List<CrewTrip>>(trips);
  }

  Future<Result<CrewTrip>> startTrip({
    required String tripId,
    required String vehicleId,
    required DateTime deviceStartedAt,
  }) async {
    final response = await dataProvider.startTrip(
      tripId: tripId,
      vehicleId: vehicleId,
      deviceStartedAt: deviceStartedAt,
    );
    return _single(response);
  }

  Future<Result<CrewTrip>> endTrip({required String tripId}) async {
    final response = await dataProvider.endTrip(tripId: tripId);
    return _single(response);
  }

  Result<CrewTrip> _single(ApiResponse response) {
    if (!response.isSuccess) return _toFailure<CrewTrip>(response);

    final trip = _parseTrip(response.data);
    if (trip == null) return const Failure<CrewTrip>(ErrorCode.unknown);
    return Success<CrewTrip>(trip);
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
    );
  }

  /// A row missing its identity is dropped rather than shown half-built: a run with no id is a
  /// run the crew could tap and not start.
  CrewTrip? _parseTrip(Map<String, Object?> data) {
    final id = data['id'];
    final routeId = data['routeId'];
    if (id is! String || routeId is! String) return null;

    return CrewTrip(
      id: id,
      routeId: routeId,
      routeCode: data['routeCode'] as String? ?? '',
      routeName: data['routeName'] as String? ?? '',
      direction: TripDirection.fromWire(data['direction'] as String?),
      status: TripStatus.fromWire(data['status'] as String?),
      stopCount: data['stopCount'] as String?,
      scheduledStartTime: data['scheduledStartTime'] as String?,
      startedAt: _parseInstant(data['startedAt']),
      endedAt: _parseInstant(data['endedAt']),
      vehicleId: data['vehicleId'] as String?,
      expectedVehicleId: data['expectedVehicleId'] as String?,
      expectedVehicleDisplayName: data['expectedVehicleDisplayName'] as String?,
      expectedVehicleRegistrationNo: data['expectedVehicleRegistrationNo'] as String?,
      cancelledReason: data['cancelledReason'] as String?,
    );
  }

  static DateTime? _parseInstant(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
