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
  ///
  /// `deliveryMode` is `INVITE` (the account is emailed a set-password link) or `PASSWORD` (the
  /// operator supplies one). `initialPassword` travels only in `PASSWORD` mode (ADR-0012).
  Future<ApiResponse> createUser({
    required String organizationId,
    String? schoolId,
    required String email,
    String? phone,
    required String firstName,
    required String lastName,
    required String roleCode,
    String? initialPassword,
    required String deliveryMode,
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
        'deliveryMode': deliveryMode,
        if (initialPassword != null && initialPassword.isNotEmpty)
          'initialPassword': initialPassword,
      },
    );
  }

  /// `POST /users/{id}/resend-invitation?organizationId=` (`PERM-USER-EDIT`) — re-sends an
  /// invitation to a pending account (ADR-0012). No idempotency key: a repeat simply issues a
  /// fresh token, which is harmless.
  Future<ApiResponse> resendInvitation({required String userId, required String organizationId}) {
    return client.post(
      '/users/$userId/resend-invitation',
      query: {'organizationId': organizationId},
    );
  }

  /// `POST /users/{id}/send-reset-code?organizationId=` (`PERM-USER-EDIT`) — emails a
  /// password-reset code to an active account, which the admin then enters themselves (ADR-0012).
  Future<ApiResponse> sendResetCode({required String userId, required String organizationId}) {
    return client.post(
      '/users/$userId/send-reset-code',
      query: {'organizationId': organizationId},
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
