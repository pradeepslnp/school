import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/vehicle_data_provider.dart';
import '../domain/vehicle_models.dart';

/// Turns vehicle transport into domain outcomes.
///
/// The bloc depends on this, never on [VehicleDataProvider] directly — matching
/// `StaffRepository`, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class VehicleRepository {
  VehicleRepository({required this.dataProvider});

  final VehicleDataProvider dataProvider;

  Future<Result<CreatedVehicle>> createVehicle({
    required String schoolId,
    required String registrationNo,
    required String displayName,
    required String vehicleType,
    required int seatingCapacity,
    String? vendorName,
  }) async {
    final response = await dataProvider.createVehicle(
      schoolId: schoolId,
      registrationNo: registrationNo.trim(),
      displayName: displayName.trim(),
      vehicleType: vehicleType,
      seatingCapacity: seatingCapacity,
      vendorName: vendorName?.trim(),
    );
    if (!response.isSuccess) return _toFailure<CreatedVehicle>(response);

    final vehicle = _parseVehicle(response.data);
    if (vehicle == null) {
      return const Failure<CreatedVehicle>(ErrorCode.internalError);
    }
    return Success<CreatedVehicle>(vehicle);
  }

  Future<Result<List<CreatedVehicle>>> listVehicles({required String schoolId}) async {
    final response = await dataProvider.listVehicles(schoolId: schoolId);
    if (!response.isSuccess) return _toFailure<List<CreatedVehicle>>(response);

    final vehicles = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseVehicle)
        .whereType<CreatedVehicle>()
        .toList(growable: false);
    return Success<List<CreatedVehicle>>(vehicles);
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

  CreatedVehicle? _parseVehicle(Map<String, Object?> data) {
    final id = data['id'];
    final schoolId = data['schoolId'];
    final registrationNo = data['registrationNo'];
    final displayName = data['displayName'];
    final vehicleType = data['vehicleType'];
    final seatingCapacity = data['seatingCapacity'];
    final status = data['status'];
    if (id is! String ||
        schoolId is! String ||
        registrationNo is! String ||
        displayName is! String ||
        vehicleType is! String ||
        seatingCapacity is! int ||
        status is! String) {
      return null;
    }
    return CreatedVehicle(
      id: id,
      schoolId: schoolId,
      registrationNo: registrationNo,
      displayName: displayName,
      vehicleType: vehicleType,
      seatingCapacity: seatingCapacity,
      vendorName: data['vendorName'] as String?,
      status: status,
    );
  }
}
