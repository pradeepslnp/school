import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for route creation (RTE-001).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console (PROJECT_STRUCTURE.md). This layer speaks endpoints and JSON only; deciding
/// what a failure means is [RouteRepository]'s job.
///
/// Contract: [`FLEET_STAFF_ROUTES_API.md`] §Routes.
class RouteDataProvider {
  RouteDataProvider({required this.client});

  final RestClient client;

  /// `POST /routes` — creates a route (`PERM-ROUTE-MANAGE`). Stop entry is a separate call
  /// (`PUT /routes/{id}/stops`), not made from this console yet — see `CreateRouteForm`.
  Future<ApiResponse> createRoute({
    required String schoolId,
    required String code,
    required String name,
    String? defaultVehicleId,
  }) {
    return client.post(
      '/routes',
      body: {
        'schoolId': schoolId,
        'code': code,
        'name': name,
        if (defaultVehicleId != null && defaultVehicleId.isNotEmpty)
          'defaultVehicleId': defaultVehicleId,
      },
    );
  }

  /// `GET /routes?schoolId=` — every route at one school (`PERM-ROUTE-VIEW`).
  Future<ApiResponse> listRoutes({required String schoolId}) {
    return client.get('/routes', query: {'schoolId': schoolId});
  }
}
