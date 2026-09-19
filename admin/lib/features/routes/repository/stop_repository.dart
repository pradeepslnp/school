import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/route_data_provider.dart';
import '../domain/stop_models.dart';

/// Turns stop transport into domain outcomes.
///
/// The bloc depends on this, never on [RouteDataProvider] directly — matching `RouteRepository`,
/// so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class StopRepository {
  StopRepository({required this.dataProvider});

  final RouteDataProvider dataProvider;

  Future<Result<List<RouteStop>>> listStops({required String routeId}) async {
    final response = await dataProvider.getStops(routeId: routeId);
    if (!response.isSuccess) return _toFailure<List<RouteStop>>(response);

    final stops = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseStop)
        .whereType<RouteStop>()
        .toList(growable: false);
    return Success<List<RouteStop>>(stops);
  }

  /// Replaces a route's whole stop list (`PUT`). The [stops] carry the order the operator built;
  /// `sequenceNo` is renumbered 1..n here so a removed middle stop never leaves a gap the server
  /// would reject (BR-ROUTE-001).
  Future<Result<List<RouteStop>>> replaceStops({
    required String routeId,
    required List<RouteStop> stops,
  }) async {
    final ordered = <Map<String, Object?>>[
      for (var i = 0; i < stops.length; i++) _toWire(stops[i], i + 1),
    ];

    final response = await dataProvider.replaceStops(routeId: routeId, stops: ordered);
    if (!response.isSuccess) return _toFailure<List<RouteStop>>(response);

    final saved = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseStop)
        .whereType<RouteStop>()
        .toList(growable: false);
    return Success<List<RouteStop>>(saved);
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: response.errorBusinessRule,
    );
  }

  Map<String, Object?> _toWire(RouteStop stop, int sequenceNo) {
    return {
      // An existing stop's id keeps it — and every student assigned to it — through the edit
      // (BR-ROUTE-009). A stop added in this editing session has none and is created.
      if (stop.id != null) 'id': stop.id,
      'sequenceNo': sequenceNo,
      'name': stop.name.trim(),
      'latitude': stop.latitude,
      'longitude': stop.longitude,
      'geofenceRadiusM': stop.geofenceRadiusM,
      if (stop.scheduledPickupTime != null && stop.scheduledPickupTime!.isNotEmpty)
        'scheduledPickupTime': _normaliseTime(stop.scheduledPickupTime!),
      if (stop.scheduledDropTime != null && stop.scheduledDropTime!.isNotEmpty)
        'scheduledDropTime': _normaliseTime(stop.scheduledDropTime!),
      if (stop.landmark != null && stop.landmark!.trim().isNotEmpty)
        'landmark': stop.landmark!.trim(),
    };
  }

  /// The wire type is a local time; the server accepts `HH:mm` and `HH:mm:ss`. Sends `HH:mm:ss`
  /// so a value round-trips unchanged.
  static String _normaliseTime(String value) {
    final trimmed = value.trim();
    final parts = trimmed.split(':');
    if (parts.length == 2) return '$trimmed:00';
    return trimmed;
  }

  RouteStop? _parseStop(Map<String, Object?> data) {
    final sequenceNo = data['sequenceNo'];
    final name = data['name'];
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    final geofenceRadiusM = data['geofenceRadiusM'];
    if (sequenceNo is! int ||
        name is! String ||
        latitude is! num ||
        longitude is! num ||
        geofenceRadiusM is! int) {
      return null;
    }
    return RouteStop(
      id: data['id'] as String?,
      sequenceNo: sequenceNo,
      name: name,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      geofenceRadiusM: geofenceRadiusM,
      scheduledPickupTime: _shortTime(data['scheduledPickupTime'] as String?),
      scheduledDropTime: _shortTime(data['scheduledDropTime'] as String?),
      landmark: data['landmark'] as String?,
    );
  }

  /// Trims a wire `HH:mm:ss` down to the `HH:mm` the editor shows.
  static String? _shortTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return value;
  }
}
