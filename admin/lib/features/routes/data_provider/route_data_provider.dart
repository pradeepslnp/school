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
    String? operatingDays,
  }) {
    return client.post(
      '/routes',
      body: {
        'schoolId': schoolId,
        'code': code,
        'name': name,
        if (defaultVehicleId != null && defaultVehicleId.isNotEmpty)
          'defaultVehicleId': defaultVehicleId,
        if (operatingDays != null && operatingDays.isNotEmpty)
          'operatingDays': operatingDays,
      },
    );
  }

  /// `PATCH /routes/{routeId}` — edits a route (`PERM-ROUTE-MANAGE`).
  ///
  /// Only the fields being changed are sent. A PATCH that resent every field would overwrite a
  /// colleague's concurrent rename with a stale value this screen never meant to change.
  Future<ApiResponse> updateRoute({
    required String routeId,
    String? name,
    String? defaultVehicleId,
    String? operatingDays,
  }) {
    return client.patch(
      '/routes/$routeId',
      body: {
        if (name != null) 'name': name,
        if (defaultVehicleId != null) 'defaultVehicleId': defaultVehicleId,
        if (operatingDays != null) 'operatingDays': operatingDays,
      },
    );
  }

  /// `GET /routes?schoolId=` — every route at one school (`PERM-ROUTE-VIEW`).
  Future<ApiResponse> listRoutes({required String schoolId}) {
    return client.get('/routes', query: {'schoolId': schoolId});
  }

  /// `GET /routes/{routeId}/stops` — the route's ordered stop list (`PERM-ROUTE-VIEW`).
  Future<ApiResponse> getStops({required String routeId}) {
    return client.get('/routes/$routeId/stops');
  }

  /// `PUT /routes/{routeId}/stops` — replaces the route's whole stop list (`PERM-ROUTE-MANAGE`).
  /// Always the full ordered set, never a single-stop edit — matching the endpoint's own
  /// contract (FLEET_STAFF_ROUTES_API.md).
  Future<ApiResponse> replaceStops({
    required String routeId,
    required List<Map<String, Object?>> stops,
  }) {
    return client.put('/routes/$routeId/stops', body: {'stops': stops});
  }
}
