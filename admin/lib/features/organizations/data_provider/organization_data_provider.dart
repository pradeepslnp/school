import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for organization and school onboarding.
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data
/// provider in this console (PROJECT_STRUCTURE.md). This layer speaks endpoints and JSON
/// only; deciding what a failure means is [OrganizationOnboardingRepository]'s job.
///
/// Contract: [`TENANCY_IDENTITY_API.md`] §Organizations, §Schools.
class OrganizationDataProvider {
  OrganizationDataProvider({required this.client});

  final RestClient client;

  /// `POST /organizations` — mints a new tenant (TEN-001, `PERM-ORG-CREATE`).
  ///
  /// No idempotency key: the API does not document one for this endpoint, and a client-side
  /// retry the operator did not ask for would mint a second organization rather than replay
  /// the first — there is no natural key here for the server to deduplicate on the way
  /// there is for, say, a boarding scan.
  Future<ApiResponse> createOrganization({
    required String code,
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) {
    return client.post(
      '/organizations',
      body: {
        'code': code,
        'name': name,
        'regionProfileCode': regionProfileCode,
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contactEmail': contactEmail,
        if (contactPhone != null && contactPhone.isNotEmpty)
          'contactPhone': contactPhone,
      },
    );
  }

  /// `GET /organizations` — every organization on the platform, `SUPER_ADMIN` only
  /// (TEN-001, `PERM-ORG-VIEW`). See `ListOrganizationsUseCase` on the backend for why holding
  /// the permission is not by itself enough — enforced there, not here.
  Future<ApiResponse> listOrganizations() {
    return client.get('/organizations');
  }

  /// `GET /schools?organizationId=` — the schools under one organization (TEN-002,
  /// `PERM-SCHOOL-VIEW`). Used by the details view to find an organization's existing school
  /// when it was not the one just created in this session.
  Future<ApiResponse> listSchools({required String organizationId}) {
    return client.get('/schools', query: {'organizationId': organizationId});
  }

  /// `GET /schools/{id}` — one school directly, by id (TEN-002, `PERM-SCHOOL-VIEW`).
  ///
  /// Unlike [listSchools], needs no `organizationId` — School Settings (A-41) loads the
  /// signed-in operator's own school from `AuthenticatedUser.schoolScopeId` alone, the same
  /// way the Drivers and Vehicles screens pre-fill from it, and a `SCHOOL_ADMIN` does not
  /// hold `PERM-ORG-VIEW` to look its organization id up first.
  Future<ApiResponse> getSchool({required String schoolId}) {
    return client.get('/schools/$schoolId');
  }

  /// `POST /schools` — the organization's first school (TEN-002, `PERM-SCHOOL-CREATE`).
  Future<ApiResponse> createSchool({
    required String organizationId,
    required String code,
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) {
    return client.post(
      '/schools',
      body: {
        'organizationId': organizationId,
        'code': code,
        'name': name,
        'timezone': timezone,
        'latitude': latitude,
        'longitude': longitude,
        'geofenceRadiusM': geofenceRadiusM,
      },
    );
  }

  /// `PATCH /organizations/{id}` — edits the details an operator may change after creation
  /// (TEN-001, `PERM-ORG-EDIT`). No `code`: it is immutable (BR-TEN-007).
  Future<ApiResponse> updateOrganization({
    required String organizationId,
    required String name,
    required String regionProfileCode,
    String? contactEmail,
    String? contactPhone,
  }) {
    return client.patch(
      '/organizations/$organizationId',
      body: {
        'name': name,
        'regionProfileCode': regionProfileCode,
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contactEmail': contactEmail,
        if (contactPhone != null && contactPhone.isNotEmpty)
          'contactPhone': contactPhone,
      },
    );
  }

  /// `POST /organizations/{id}/suspend` (TEN-004, `PERM-ORG-SUSPEND`, BR-TEN-006). No body:
  /// the target is entirely in the path, and who is acting comes from the auth token, the
  /// same shape as every other write in this provider.
  Future<ApiResponse> suspendOrganization({required String organizationId}) {
    return client.post('/organizations/$organizationId/suspend');
  }

  /// `POST /organizations/{id}/reactivate` — the reverse of [suspendOrganization]
  /// (BR-TEN-006).
  Future<ApiResponse> reactivateOrganization({required String organizationId}) {
    return client.post('/organizations/$organizationId/reactivate');
  }

    /// `PATCH /schools/{id}` — edits a school's own details (TEN-002, `PERM-SCHOOL-EDIT`).
  ///
  /// `organizationId` travels in the body even though the school id is already in the path —
  /// the server needs it to establish tenant context before it can read the row at all; see
  /// `UpdateSchoolCommand`'s documentation on the backend.
  Future<ApiResponse> updateSchool({
    required String schoolId,
    required String organizationId,
    required String name,
    required String timezone,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) {
    return client.patch(
      '/schools/$schoolId',
      body: {
        'organizationId': organizationId,
        'name': name,
        'timezone': timezone,
        'latitude': latitude,
        'longitude': longitude,
        'geofenceRadiusM': geofenceRadiusM,
      },
    );
  }
}
