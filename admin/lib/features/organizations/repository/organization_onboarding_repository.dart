import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/organization_data_provider.dart';
import '../domain/onboarding_models.dart';

/// Turns organization/school onboarding transport into domain outcomes.
///
/// The bloc depends on this, never on [OrganizationDataProvider] — matching
/// `LoginRepository`, so a bloc test runs with a fake repository and no HTTP at all.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class OrganizationOnboardingRepository {
  OrganizationOnboardingRepository({required this.dataProvider});

  final OrganizationDataProvider dataProvider;

  Future<Result<CreatedOrganization>> createOrganization({
    required String code,
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) async {
    final response = await dataProvider.createOrganization(
      code: code.trim(),
      name: name.trim(),
      regionProfileCode: regionProfileCode.trim(),
      contactEmail: contactEmail?.trim(),
      contactPhone: contactPhone?.trim(),
    );
    if (!response.isSuccess) return _toFailure<CreatedOrganization>(response);

    final organization = _parseOrganization(response.data);
    if (organization == null) {
      // A 2xx we cannot read is a contract breach, not a validation problem — matching
      // LoginRepository's treatment of the same case.
      return const Failure<CreatedOrganization>(ErrorCode.internalError);
    }
    return Success<CreatedOrganization>(organization);
  }

  Future<Result<CreatedSchool>> createSchool({
    required String organizationId,
    required String code,
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) async {
    final response = await dataProvider.createSchool(
      organizationId: organizationId,
      code: code.trim(),
      name: name.trim(),
      timezone: timezone,
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusM: geofenceRadiusM,
    );
    if (!response.isSuccess) return _toFailure<CreatedSchool>(response);

    final school = _parseSchool(response.data);
    if (school == null) {
      return const Failure<CreatedSchool>(ErrorCode.internalError);
    }
    return Success<CreatedSchool>(school);
  }

  /// Every organization on the platform (`SUPER_ADMIN` only) — backs the Organizations list
  /// screen (A-41).
  Future<Result<List<CreatedOrganization>>> listOrganizations() async {
    final response = await dataProvider.listOrganizations();
    if (!response.isSuccess) return _toFailure<List<CreatedOrganization>>(response);

    final organizations = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseOrganization)
        .whereType<CreatedOrganization>()
        .toList(growable: false);
    return Success<List<CreatedOrganization>>(organizations);
  }

  /// The schools under one organization — used to find its existing school when the operator
  /// opens an organization from the list rather than having just created it (TEN-002).
  Future<Result<List<CreatedSchool>>> listSchools({required String organizationId}) async {
    final response = await dataProvider.listSchools(organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<List<CreatedSchool>>(response);

    final schools = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseSchool)
        .whereType<CreatedSchool>()
        .toList(growable: false);
    return Success<List<CreatedSchool>>(schools);
  }

  /// One school directly, by id — backs School Settings (A-41) for a `SCHOOL_ADMIN`, who
  /// knows their own school id (`AuthenticatedUser.schoolScopeId`) but, unlike `ORG_ADMIN`
  /// or `SUPER_ADMIN`, holds no `PERM-ORG-VIEW` to reach it via the Organizations list.
  Future<Result<CreatedSchool>> getSchool({required String schoolId}) async {
    final response = await dataProvider.getSchool(schoolId: schoolId);
    if (!response.isSuccess) return _toFailure<CreatedSchool>(response);

    final school = _parseSchool(response.data);
    if (school == null) {
      return const Failure<CreatedSchool>(ErrorCode.internalError);
    }
    return Success<CreatedSchool>(school);
  }

  Future<Result<CreatedOrganization>> updateOrganization({
    required String organizationId,
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) async {
    final response = await dataProvider.updateOrganization(
      organizationId: organizationId,
      name: name.trim(),
      regionProfileCode: regionProfileCode.trim(),
      contactEmail: contactEmail?.trim(),
      contactPhone: contactPhone?.trim(),
    );
    if (!response.isSuccess) return _toFailure<CreatedOrganization>(response);

    final organization = _parseOrganization(response.data);
    if (organization == null) {
      return const Failure<CreatedOrganization>(ErrorCode.internalError);
    }
    return Success<CreatedOrganization>(organization);
  }

  /// `POST /organizations/{id}/suspend` — blocks the organization's user access on its
  /// operators' next request without touching any data (TEN-004, `PERM-ORG-SUSPEND`,
  /// BR-TEN-006). `SUPER_ADMIN` only.
  Future<Result<CreatedOrganization>> suspendOrganization({
    required String organizationId,
  }) async {
    final response = await dataProvider.suspendOrganization(organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<CreatedOrganization>(response);

    final organization = _parseOrganization(response.data);
    if (organization == null) {
      return const Failure<CreatedOrganization>(ErrorCode.internalError);
    }
    return Success<CreatedOrganization>(organization);
  }

  /// The reverse of [suspendOrganization] (BR-TEN-006). `SUPER_ADMIN` only.
  Future<Result<CreatedOrganization>> reactivateOrganization({
    required String organizationId,
  }) async {
    final response = await dataProvider.reactivateOrganization(organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<CreatedOrganization>(response);

    final organization = _parseOrganization(response.data);
    if (organization == null) {
      return const Failure<CreatedOrganization>(ErrorCode.internalError);
    }
    return Success<CreatedOrganization>(organization);
  }

  Future<Result<CreatedSchool>> updateSchool({
    required String schoolId,
    required String organizationId,
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) async {
    final response = await dataProvider.updateSchool(
      schoolId: schoolId,
      organizationId: organizationId,
      name: name.trim(),
      timezone: timezone,
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusM: geofenceRadiusM,
    );
    if (!response.isSuccess) return _toFailure<CreatedSchool>(response);

    final school = _parseSchool(response.data);
    if (school == null) {
      return const Failure<CreatedSchool>(ErrorCode.internalError);
    }
    return Success<CreatedSchool>(school);
  }

  /// Maps an unsuccessful response onto the shared error vocabulary — matching
  /// `LoginRepository._toFailure`.
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

  CreatedOrganization? _parseOrganization(Map<String, Object?> data) {
    final id = data['id'];
    final code = data['code'];
    final name = data['name'];
    final regionProfileCode = data['regionProfileCode'];
    final status = data['status'];
    if (id is! String ||
        code is! String ||
        name is! String ||
        regionProfileCode is! String ||
        status is! String) {
      return null;
    }
    return CreatedOrganization(
      id: id,
      code: code,
      name: name,
      regionProfileCode: regionProfileCode,
      status: status,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
    );
  }

  CreatedSchool? _parseSchool(Map<String, Object?> data) {
    final id = data['id'];
    final organizationId = data['organizationId'];
    final code = data['code'];
    final name = data['name'];
    final timezone = data['timezone'];
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    final geofenceRadiusM = data['geofenceRadiusM'];
    if (id is! String ||
        organizationId is! String ||
        code is! String ||
        name is! String ||
        timezone is! String ||
        latitude == null ||
        longitude == null ||
        geofenceRadiusM is! int) {
      return null;
    }
    return CreatedSchool(
      id: id,
      organizationId: organizationId,
      code: code,
      name: name,
      timezone: timezone,
      // The API returns these as JSON numbers, which `dart:convert` decodes as `int` when the
      // value happens to have no fractional part (e.g. `28`) — `num.toDouble()` normalises
      // either shape rather than the parse failing on exactly-whole coordinates.
      latitude: (latitude as num).toDouble(),
      longitude: (longitude as num).toDouble(),
      geofenceRadiusM: geofenceRadiusM,
    );
  }
}
