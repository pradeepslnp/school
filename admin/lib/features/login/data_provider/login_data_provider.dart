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
///
/// > **Server gap, deliberate.** `POST /auth/login` is documented in AUTHENTICATION_API.md
/// > but is not implemented in `guardian-backend` — `AuthController` currently exposes the
/// > OTP path and `/auth/refresh` only. This client is written to the documented contract
/// > because documentation is the source of truth (INSTRUCTIONS.md §Documentation Rule), not
/// > to a shape invented to fit today's server. Sign-in returns
/// > [ErrorCode.dependencyUnavailable] until the endpoint lands; nothing here changes when
/// > it does.
class LoginDataProvider {
  LoginDataProvider({required this.client});

  /// Identifies this client to the server.
  ///
  /// It is what decides the refresh-token lifetime — shortest of the four clients, because
  /// the console is the highest-privilege human surface on the platform
  /// (SECURITY_ARCHITECTURE.md §Authentication). The server refuses an unknown value rather
  /// than defaulting, so this string is part of the contract.
  static const String clientType = 'ADMIN_WEB';

  final RestClient client;

  /// `POST /auth/login` — staff email and password (IAM-001).
  ///
  /// Not given an idempotency key, so [RestClient] will not retry it. A repeated sign-in
  /// attempt counts against the lockout threshold (BR-IAM-011), and an automatic retry the
  /// operator did not make could lock an account they are trying to use.
  Future<ApiResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        'clientType': clientType,
      },
      // No session exists yet, so no Authorization header should be sent.
      authenticated: false,
    );
  }

  /// `POST /auth/refresh` — rotates the session.
  ///
  /// Deliberately never given an idempotency key: the presented refresh token is consumed
  /// server-side, and a second attempt with the same one is indistinguishable from theft.
  /// Reuse revokes the entire token family (BR-IAM-009).
  Future<ApiResponse> refresh({required String refreshToken}) {
    return client.post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
      authenticated: false,
    );
  }

  /// `POST /auth/logout` — revokes the session server-side.
  ///
  /// Best-effort. The local clear does not wait on it and does not depend on it: a failed
  /// revocation is recoverable — the access token dies in fifteen minutes — while leaving a
  /// live session in a browser tab the operator believes they closed is not.
  Future<ApiResponse> signOut() => client.post('/auth/logout');
}
