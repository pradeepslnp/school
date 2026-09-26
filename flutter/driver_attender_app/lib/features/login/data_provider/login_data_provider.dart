import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for the authentication endpoints.
///
/// Calls [RestClient] rather than `package:http` directly, so timeouts, headers, retry
/// policy, and response decoding stay decided in one place (PROJECT_STRUCTURE.md).
///
/// This layer speaks endpoints and JSON. Deciding what a failure *means* is the repository's
/// job, and keeping that split is what lets the repository be tested without a socket.
///
/// Contract: [`AUTHENTICATION_API.md`].
class LoginDataProvider {
  LoginDataProvider({required this.client});

  /// Identifies this app to the server. It is what decides the refresh-token lifetime —
  /// seven days for a driver handset, against ninety for a parent's phone, because a driver
  /// device is shared and changes hands between shifts (SECURITY_ARCHITECTURE.md). The server
  /// refuses an unknown value rather than defaulting, so this string is part of the contract.
  static const String clientType = 'DRIVER_APP';

  final RestClient client;

  /// `POST /auth/otp/request` — always `202`, whether or not the number is registered.
  Future<ApiResponse> requestOtp({required String phone}) {
    return client.post(
      '/auth/otp/request',
      // See parent_app's LoginDataProvider: a hint the server uses only on a magic-OTP build,
      // to pick the crew account when the number also exists in another organization.
      body: {'phone': phone, 'clientType': 'DRIVER_APP'},
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
      body: {'phone': phone, 'otp': otp, 'clientType': clientType},
      authenticated: false,
    );
  }

  /// `POST /auth/refresh` — rotates the session.
  ///
  /// Not retried, and deliberately never given an idempotency key: the presented refresh
  /// token is consumed server-side, and a second attempt with the same one is
  /// indistinguishable from theft. Reuse revokes the entire token family (BR-IAM-009).
  Future<ApiResponse> refresh({required String refreshToken}) {
    return client.post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
      authenticated: false,
    );
  }

  /// `POST /auth/logout` — revokes the session server-side.
  ///
  /// Best-effort by design. The local wipe does not wait on it and does not depend on it: a
  /// driver signing off in a depot with no signal must still leave a clean handset, and a
  /// server revocation that failed is recoverable while child data left on a shared device
  /// is not.
  Future<ApiResponse> logout() => client.post('/auth/logout');
}
