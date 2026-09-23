import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../../../core/offline/outbound_queue.dart';
import '../../../core/offline/outbound_record.dart';
import '../../../core/time/clock.dart';
import '../data_provider/trip_data_provider.dart';
import '../domain/manifest_models.dart';
import '../domain/trip_models.dart';

/// Decides what the crew's day means (MOD-08, TRP-002/004).
///
/// Depends on a data provider only. Nothing above this layer sees an HTTP status code.
class TripRepository {
  TripRepository({
    required this.dataProvider,
    required this.outboundQueue,
    required this.clock,
  });

  final TripDataProvider dataProvider;

  /// Boarding events go through the queue, never straight to the network (ADR-0008).
  ///
  /// This is the difference between the trip controls above and the boarding write below.
  /// Starting a run needs an answer — eligibility, double-booking, who won the start race — so it
  /// is an online call the crew waits for. A child stepping onto a bus needs no answer: it has
  /// already happened, and the only job is never to lose it. Queue first, sync later.
  final OutboundQueue outboundQueue;

  final Clock clock;

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

  Future<Result<List<ManifestChild>>> manifest({required String tripId}) async {
    final response = await dataProvider.fetchManifest(tripId: tripId);
    if (!response.isSuccess) return _toFailure<List<ManifestChild>>(response);

    final children = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseChild)
        .whereType<ManifestChild>()
        .toList(growable: false);
    return Success<List<ManifestChild>>(children);
  }

  /// Records a board or an alight (BRD-001..004).
  ///
  /// Returns as soon as the event is durably queued — it does not wait for the network, and must
  /// not: a child at the door of a bus does not wait for a spinner. The queue owns the retry, the
  /// `clientEventId` that makes the retry safe (BR-BOARD-009), and the clock-skew estimate that
  /// tells an investigation what this handset believed the time was (BR-BOARD-008).
  Future<void> recordBoarding({
    required String tripId,
    required String studentId,
    required String? stopId,
    required bool isBoarding,
    String? overrideReason,
  }) async {
    await outboundQueue.enqueue(
      kind: OutboundKind.boardingEvent,
      tripId: tripId,
      occurredAt: clock.nowUtc(),
      payload: {
        'studentId': studentId,
        if (stopId != null) 'stopId': stopId,
        'eventType': isBoarding ? 'BOARD' : 'ALIGHT',
        // MANUAL, honestly: the crew selected this child from the manifest. Claiming QR_SCAN
        // would record a scan that never happened (BR-BOARD-002).
        'verificationMethod': 'MANUAL',
        if (overrideReason != null && overrideReason.trim().isNotEmpty) ...{
          'isOverride': true,
          'overrideReason': overrideReason.trim(),
        },
      },
    );
  }

  ManifestChild? _parseChild(Map<String, Object?> data) {
    final studentId = data['studentId'];
    final studentName = data['studentName'];
    if (studentId is! String || studentName is! String) return null;

    return ManifestChild(
      studentId: studentId,
      studentName: studentName,
      className: data['className'] as String?,
      expectedStopId: data['expectedStopId'] as String?,
      expectedStopName: data['expectedStopName'] as String?,
      stopSequenceNo: (data['stopSequenceNo'] as num?)?.toInt() ?? 0,
      scheduledStopTime: data['scheduledStopTime'] as String?,
      status: ManifestEntryStatus.fromWire(data['status'] as String?),
      lastEventAt: _parseInstant(data['lastEventAt']),
    );
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
