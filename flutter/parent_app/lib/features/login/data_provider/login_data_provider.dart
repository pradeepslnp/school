import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for the authentication endpoints.
///
/// Calls [RestClient] rather than `package:http` directly, so timeouts, headers, retry policy,
/// and response decoding stay decided in one place
/// (docs/06-development/PROJECT_STRUCTURE.md).
///
/// This layer speaks endpoints and JSON. Deciding what a failure *means* is the repository's
/// job, and keeping that split is what lets the repository be tested without a socket.
///
/// Contract: docs/04-api/AUTHENTICATION_API.md
class LoginDataProvider {
  LoginDataProvider({required this.client});

  final RestClient client;

  /// `POST /auth/otp/request` — always `202`, whether or not the number is registered.
  ///
  /// The endpoint deliberately does not reveal registration status: an attacker able to
  /// enumerate registered numbers holds a list of families at a named school.
  Future<ApiResponse> requestOtp({required String phone}) {
    return client.post(
      '/auth/otp/request',
      body: {'phone': phone},
      // No session exists yet, so no Authorization header should be sent.
      authenticated: false,
    );
  }

  /// `POST /auth/otp/verify` — exchanges a code for a session.
  Future<ApiResponse> verifyOtp({
    required String phone,
    required String otp,
  }) {
    return client.post(
      '/auth/otp/verify',
      body: {'phone': phone, 'otp': otp, 'clientType': 'PARENT_APP'},
      authenticated: false,
    );
  }

  /// `POST /auth/refresh` — rotates the session.
  ///
  /// Not retried: the presented refresh token is consumed by the server, and a second
  /// attempt with the same token is indistinguishable from theft. Reuse invalidates the
  /// whole session family (BR-IAM-009).
  Future<ApiResponse> refresh({required String refreshToken}) {
    return client.post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
      authenticated: false,
    );
  }
}
