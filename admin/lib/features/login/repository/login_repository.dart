import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_manager.dart';
import '../data_provider/login_data_provider.dart';

/// Turns authentication transport into domain outcomes.
///
/// The bloc depends on this, never on [LoginDataProvider] — so a bloc test runs with a fake
/// repository and no HTTP at all, and a transport change never reaches presentation
/// (ENGINEERING_PRINCIPLES.md §4).
///
/// Every path returns a [Result]; nothing throws for an expected failure. A wrong password
/// is an ordinary outcome, not an exception.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
///
/// Implements [SessionRefresher] so [SessionManager] can rotate tokens without knowing which
/// endpoint does it.
class LoginRepository implements SessionRefresher {
  LoginRepository({required this.dataProvider, DateTime Function()? now})
      : _now = now ?? _systemNowUtc;

  final LoginDataProvider dataProvider;

  /// Injected so a test can assert the computed expiry without waiting.
  final DateTime Function() _now;

  /// Signs a member of staff in with email and password.
  ///
  /// The email is trimmed but not lowercased and not pattern-checked. Address validation
  /// belongs to the server, which owns the account: a client-side pattern that rejects a
  /// valid address produces an operator who cannot sign in and has nothing to correct.
  Future<Result<Session>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await dataProvider.signIn(
      email: email.trim(),
      password: password,
    );
    if (!response.isSuccess) return _toFailure<Session>(response);

    final session = _parseSession(response.data);
    if (session == null) {
      // A 2xx we cannot read is a contract breach, not a credential problem. Reporting
      // "wrong password" here would send an operator round a loop they cannot escape.
      return const Failure<Session>(ErrorCode.internalError);
    }
    return Success<Session>(session);
  }

  /// Asks for a one-time sign-in code by email (IAM-001, ADR-0012).
  ///
  /// Succeeds whenever the server accepted the request — which it does whether or not the address
  /// has an account, so a `Success` means "we asked", not "an account was found". The screen says
  /// so, because saying more would leak who has an account.
  Future<Result<void>> requestEmailOtp({required String email}) async {
    final response = await dataProvider.requestEmailOtp(email: email.trim());
    if (response.isSuccess) return const Success<void>(null);
    return _toFailure<void>(response);
  }

  /// Exchanges an emailed code for a session (IAM-001, ADR-0012).
  Future<Result<Session>> signInWithEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await dataProvider.verifyEmailOtp(
      email: email.trim(),
      otp: otp.trim(),
    );
    if (!response.isSuccess) return _toFailure<Session>(response);

    final session = _parseSession(response.data);
    if (session == null) return const Failure<Session>(ErrorCode.internalError);
    return Success<Session>(session);
  }

  @override
  Future<Result<Session>> refreshSession(String refreshToken) async {
    final response = await dataProvider.refresh(refreshToken: refreshToken);
    if (!response.isSuccess) return _toFailure<Session>(response);

    final session = _parseSession(response.data);
    if (session == null) return const Failure<Session>(ErrorCode.internalError);
    return Success<Session>(session);
  }

  /// Tells the server the session is over.
  ///
  /// The caller must not make the local clear conditional on this succeeding — see
  /// [LoginDataProvider.signOut].
  Future<Result<void>> revokeSessionOnServer() async {
    final response = await dataProvider.signOut();
    if (response.isSuccess) return const Success<void>(null);
    return _toFailure<void>(response);
  }

  /// Maps an unsuccessful response onto the shared error vocabulary.
  ///
  /// A transport failure carries no error code, so it is distinguished here rather than by
  /// catching exceptions — [RestClient] already converts timeouts and browser-level faults
  /// into [ApiResponse.transportFailure], so every outcome arrives on one path.
  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }

    // A 429 with no parseable body still has to be readable as throttling: the sign-in
    // endpoints are the most heavily rate-limited in the platform, and a gateway may answer
    // before the API does (AUTHENTICATION_API.md).
    if (response.isRateLimited && response.errorCode == null) {
      return Failure<T>(ErrorCode.rateLimitExceeded);
    }

    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: response.errorBusinessRule,
    );
  }

  Session? _parseSession(Map<String, Object?> data) {
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final expiresIn = data['expiresIn'];
    final user = data['user'];

    if (accessToken is! String ||
        refreshToken is! String ||
        expiresIn is! int ||
        user is! Map<String, Object?>) {
      return null;
    }

    final parsedUser = AuthenticatedUser.fromJson(user);
    if (parsedUser == null) return null;

    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      // Derived from the server's *interval* rather than an absolute timestamp, so a
      // workstation clock that is minutes out does not make a valid token look expired or
      // an expired one look valid.
      expiresAt: _now().add(Duration(seconds: expiresIn)),
      user: parsedUser,
    );
  }

  static DateTime _systemNowUtc() => DateTime.now().toUtc();
}
