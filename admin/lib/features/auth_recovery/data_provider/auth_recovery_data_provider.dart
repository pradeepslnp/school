import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for account activation and password recovery (ADR-0012, features IAM-009/IAM-010).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider in
/// this console. Every call is unauthenticated — the caller holds a link or an email address, not a
/// session — so none sends an `Authorization` header. This layer speaks endpoints and JSON only;
/// deciding what a failure means is [AuthRecoveryRepository]'s job.
///
/// Contract: `AUTHENTICATION_API.md` §Account activation & recovery.
class AuthRecoveryDataProvider {
  AuthRecoveryDataProvider({required this.client});

  final RestClient client;

  /// `POST /auth/invitations/accept` — sets the invitee's first password and activates the
  /// account. No idempotency key: the token is single-use server-side, so a repeat simply fails
  /// as already-used rather than doing anything twice.
  Future<ApiResponse> acceptInvitation({required String token, required String password}) {
    return client.post(
      '/auth/invitations/accept',
      body: {'token': token, 'password': password},
      authenticated: false,
    );
  }

  /// `POST /auth/password-reset/request` — asks for a reset link. Always accepted (202), whether or
  /// not the address has an account, so the response reveals nothing (OWASP anti-enumeration).
  Future<ApiResponse> requestPasswordReset({required String email}) {
    return client.post(
      '/auth/password-reset/request',
      body: {'email': email},
      authenticated: false,
    );
  }

  /// `POST /auth/password-reset/confirm` — verifies the emailed code, sets the new password, and
  /// ends every existing session. The email + code together identify the account (the 6-digit code
  /// is not unique on its own), mirroring phone sign-in.
  Future<ApiResponse> confirmPasswordReset({
    required String email,
    required String otp,
    required String password,
  }) {
    return client.post(
      '/auth/password-reset/confirm',
      body: {'email': email, 'otp': otp, 'password': password},
      authenticated: false,
    );
  }
}
