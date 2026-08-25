import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for administrative-user management (IAM-005, IAM-008, screen A-43).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console. This layer speaks endpoints and JSON only; deciding what a failure means
/// is [UserRepository]'s job.
///
/// Contract: `TENANCY_IDENTITY_API.md` §Users.
class UserDataProvider {
  UserDataProvider({required this.client});

  final RestClient client;

  /// `GET /users?organizationId=` — every administrative account in one organization
  /// (`PERM-USER-VIEW`). See `UserController` on the backend for why `organizationId` travels
  /// on every call rather than being resolved from the caller's own session.
  Future<ApiResponse> listUsers({required String organizationId}) {
    return client.get('/users', query: {'organizationId': organizationId});
  }

  /// `POST /users` — creates an administrative login (`PERM-USER-CREATE`). `schoolId` is
  /// omitted for an organization-scoped role; see `CreateAdministrativeUserUseCase`.
  Future<ApiResponse> createUser({
    required String organizationId,
    String? schoolId,
    required String email,
    String? phone,
    required String firstName,
    required String lastName,
    required String roleCode,
    required String initialPassword,
  }) {
    return client.post(
      '/users',
      body: {
        'organizationId': organizationId,
        if (schoolId != null) 'schoolId': schoolId,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'roleCode': roleCode,
        'initialPassword': initialPassword,
      },
    );
  }

  /// `PATCH /users/{id}` — edits name and locale (`PERM-USER-EDIT`). Role and scope are not
  /// editable this way — see `UpdateAdministrativeUserCommand` on the backend.
  Future<ApiResponse> updateUser({
    required String userId,
    required String organizationId,
    required String firstName,
    required String lastName,
    required String preferredLocale,
  }) {
    return client.patch(
      '/users/$userId',
      body: {
        'organizationId': organizationId,
        'firstName': firstName,
        'lastName': lastName,
        'preferredLocale': preferredLocale,
      },
    );
  }

  /// `PATCH /users/{id}/deactivate` (`PERM-USER-DEACTIVATE`).
  Future<ApiResponse> deactivateUser({required String userId, required String organizationId}) {
    return client.patch('/users/$userId/deactivate', query: {'organizationId': organizationId});
  }

  /// `PATCH /users/{id}/reactivate` (`PERM-USER-DEACTIVATE`).
  Future<ApiResponse> reactivateUser({required String userId, required String organizationId}) {
    return client.patch('/users/$userId/reactivate', query: {'organizationId': organizationId});
  }
}
