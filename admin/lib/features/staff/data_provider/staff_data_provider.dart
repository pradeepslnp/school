import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for transport-staff (driver/attendant) registration.
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console (PROJECT_STRUCTURE.md). This layer speaks endpoints and JSON only; deciding
/// what a failure means is [StaffRepository]'s job.
///
/// Contract: [`FLEET_STAFF_ROUTES_API.md`] §Transport Staff.
class StaffDataProvider {
  StaffDataProvider({required this.client});

  final RestClient client;

  /// `POST /transport-staff` — registers a driver or attendant (STF-001, `PERM-STAFF-MANAGE`)
  /// and, as of `CreateTransportStaffUseCase`'s own change, provisions their driver-app sign-in
  /// in the same request — there is no separate "activate" step to call afterwards.
  Future<ApiResponse> createStaff({
    required String schoolId,
    required String staffType,
    required String firstName,
    required String lastName,
    required String phone,
    String? employeeCode,
    String? vendorName,
  }) {
    return client.post(
      '/transport-staff',
      body: {
        'schoolId': schoolId,
        'staffType': staffType,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        if (employeeCode != null && employeeCode.isNotEmpty) 'employeeCode': employeeCode,
        if (vendorName != null && vendorName.isNotEmpty) 'vendorName': vendorName,
      },
    );
  }

  /// `GET /transport-staff?schoolId=` — every driver/attendant at one school (STF-001,
  /// `PERM-STAFF-MANAGE`).
  Future<ApiResponse> listStaff({required String schoolId}) {
    return client.get('/transport-staff', query: {'schoolId': schoolId});
  }

  /// `PATCH /transport-staff/{staffId}` — updates name, phone, employee code, and vendor name
  /// (STF-001, `PERM-STAFF-MANAGE`). `staffType` and `schoolId` are not here: see
  /// `UpdateTransportStaffUseCase`'s own documentation for why a type change is not offered as
  /// an edit, and `OrganizationDetailsView`'s treatment of fixed codes for the same reasoning
  /// applied to school.
  Future<ApiResponse> updateStaff({
    required String staffId,
    required String firstName,
    required String lastName,
    required String phone,
    String? employeeCode,
    String? vendorName,
  }) {
    return client.patch(
      '/transport-staff/$staffId',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        if (employeeCode != null && employeeCode.isNotEmpty) 'employeeCode': employeeCode,
        if (vendorName != null && vendorName.isNotEmpty) 'vendorName': vendorName,
      },
    );
  }
}
