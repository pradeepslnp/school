import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for vehicle registration (FLT-001).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console (PROJECT_STRUCTURE.md). This layer speaks endpoints and JSON only; deciding
/// what a failure means is [VehicleRepository]'s job.
///
/// Contract: [`FLEET_STAFF_ROUTES_API.md`] §Vehicles.
class VehicleDataProvider {
  VehicleDataProvider({required this.client});

  final RestClient client;

  /// `POST /vehicles` — registers a vehicle (`PERM-VEHICLE-MANAGE`).
  Future<ApiResponse> createVehicle({
    required String schoolId,
    required String registrationNo,
    required String displayName,
    required String vehicleType,
    required int seatingCapacity,
    String? vendorName,
  }) {
    return client.post(
      '/vehicles',
      body: {
        'schoolId': schoolId,
        'registrationNo': registrationNo,
        'displayName': displayName,
        'vehicleType': vehicleType,
        'seatingCapacity': seatingCapacity,
        if (vendorName != null && vendorName.isNotEmpty) 'vendorName': vendorName,
      },
    );
  }

  /// `GET /vehicles?schoolId=` — every vehicle at one school (`PERM-VEHICLE-VIEW`).
  Future<ApiResponse> listVehicles({required String schoolId}) {
    return client.get('/vehicles', query: {'schoolId': schoolId});
  }
}
