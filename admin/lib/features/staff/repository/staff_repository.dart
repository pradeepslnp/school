import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/staff_data_provider.dart';
import '../domain/staff_models.dart';

/// Turns transport-staff transport into domain outcomes.
///
/// The bloc depends on this, never on [StaffDataProvider] directly — matching
/// `OrganizationOnboardingRepository`, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class StaffRepository {
  StaffRepository({required this.dataProvider});

  final StaffDataProvider dataProvider;

  Future<Result<CreatedStaff>> createStaff({
    required String schoolId,
    required String staffType,
    required String firstName,
    required String lastName,
    required String phone,
    String? employeeCode,
    String? vendorName,
  }) async {
    final response = await dataProvider.createStaff(
      schoolId: schoolId,
      staffType: staffType,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      employeeCode: employeeCode?.trim(),
      vendorName: vendorName?.trim(),
    );
    if (!response.isSuccess) return _toFailure<CreatedStaff>(response);

    final staff = _parseStaff(response.data);
    if (staff == null) {
      // A 2xx we cannot read is a contract breach, not a validation problem — matching
      // OrganizationOnboardingRepository's treatment of the same case.
      return const Failure<CreatedStaff>(ErrorCode.internalError);
    }
    return Success<CreatedStaff>(staff);
  }

  Future<Result<CreatedStaff>> updateStaff({
    required String staffId,
    required String firstName,
    required String lastName,
    required String phone,
    String? employeeCode,
    String? vendorName,
  }) async {
    final response = await dataProvider.updateStaff(
      staffId: staffId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      employeeCode: employeeCode?.trim(),
      vendorName: vendorName?.trim(),
    );
    if (!response.isSuccess) return _toFailure<CreatedStaff>(response);

    final staff = _parseStaff(response.data);
    if (staff == null) {
      return const Failure<CreatedStaff>(ErrorCode.internalError);
    }
    return Success<CreatedStaff>(staff);
  }

  Future<Result<List<CreatedStaff>>> listStaff({required String schoolId}) async {
    final response = await dataProvider.listStaff(schoolId: schoolId);
    if (!response.isSuccess) return _toFailure<List<CreatedStaff>>(response);

    final staff = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseStaff)
        .whereType<CreatedStaff>()
        .toList(growable: false);
    return Success<List<CreatedStaff>>(staff);
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

  CreatedStaff? _parseStaff(Map<String, Object?> data) {
    final id = data['id'];
    final schoolId = data['schoolId'];
    final staffType = data['staffType'];
    final firstName = data['firstName'];
    final lastName = data['lastName'];
    final phone = data['phone'];
    final verificationStatus = data['verificationStatus'];
    final active = data['active'];
    if (id is! String ||
        schoolId is! String ||
        staffType is! String ||
        firstName is! String ||
        lastName is! String ||
        phone is! String ||
        verificationStatus is! String ||
        active is! bool) {
      return null;
    }
    return CreatedStaff(
      id: id,
      schoolId: schoolId,
      userId: data['userId'] as String?,
      staffType: staffType,
      employeeCode: data['employeeCode'] as String?,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      vendorName: data['vendorName'] as String?,
      verificationStatus: verificationStatus,
      active: active,
    );
  }
}
