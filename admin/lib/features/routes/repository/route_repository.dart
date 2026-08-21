import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/route_data_provider.dart';
import '../domain/route_models.dart';

/// Turns route transport into domain outcomes.
///
/// The bloc depends on this, never on [RouteDataProvider] directly — matching
/// `VehicleRepository`, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class RouteRepository {
  RouteRepository({required this.dataProvider});

  final RouteDataProvider dataProvider;

  Future<Result<CreatedRoute>> createRoute({
    required String schoolId,
    required String code,
    required String name,
    String? defaultVehicleId,
  }) async {
    final response = await dataProvider.createRoute(
      schoolId: schoolId,
      code: code.trim(),
      name: name.trim(),
      defaultVehicleId: defaultVehicleId?.trim(),
    );
    if (!response.isSuccess) return _toFailure<CreatedRoute>(response);

    final route = _parseRoute(response.data);
    if (route == null) {
      return const Failure<CreatedRoute>(ErrorCode.internalError);
    }
    return Success<CreatedRoute>(route);
  }

  Future<Result<List<CreatedRoute>>> listRoutes({required String schoolId}) async {
    final response = await dataProvider.listRoutes(schoolId: schoolId);
    if (!response.isSuccess) return _toFailure<List<CreatedRoute>>(response);

    final routes = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseRoute)
        .whereType<CreatedRoute>()
        .toList(growable: false);
    return Success<List<CreatedRoute>>(routes);
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

  CreatedRoute? _parseRoute(Map<String, Object?> data) {
    final id = data['id'];
    final schoolId = data['schoolId'];
    final code = data['code'];
    final name = data['name'];
    final active = data['active'];
    if (id is! String || schoolId is! String || code is! String || name is! String || active is! bool) {
      return null;
    }
    return CreatedRoute(
      id: id,
      schoolId: schoolId,
      code: code,
      name: name,
      defaultVehicleId: data['defaultVehicleId'] as String?,
      active: active,
    );
  }
}
