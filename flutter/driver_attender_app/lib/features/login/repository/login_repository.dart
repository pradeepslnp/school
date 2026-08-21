import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/time/clock.dart';
import '../data_provider/login_data_provider.dart';

/// Turns authentication transport into domain outcomes.
///
/// The bloc depends on this, never on [LoginDataProvider] — so a bloc test runs with a fake
/// repository and no HTTP at all, and a transport change never reaches presentation
/// (ENGINEERING_PRINCIPLES.md §4).
///
/// Every path returns a [Result]; nothing throws for an expected failure. A wrong OTP is an
/// ordinary outcome, not an exception.
///
/// Implements [SessionRefresher] so [SessionManager] can rotate tokens without knowing which
/// endpoint does it.
class LoginRepository implements SessionRefresher {
  LoginRepository({required this.dataProvider, required Clock clock})
      : _clock = clock;

  final LoginDataProvider dataProvider;
  final Clock _clock;

  /// Requests a one-time code.
  ///
  /// Succeeds whether or not the number is registered — the API deliberately does not say,
  /// and neither does this. An attacker able to tell a registered number from an
  /// unregistered one holds a roster of a named school's staff.
  Future<Result<void>> requestOtp({required String phone}) async {
    final response = await dataProvider.requestOtp(phone: phone);
    if (response.isSuccess) return const Success<void>(null);
    return _toFailure<void>(response);
  }

  Future<Result<Session>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await dataProvider.verifyOtp(phone: phone, otp: otp);
    if (!response.isSuccess) return _toFailure<Session>(response);

    final session = _parseSession(response.data);
    if (session == null) {
      // A 2xx we cannot read is a contract breach, not a credential problem. Reporting
      // "wrong code" here would send a driver round a loop they cannot escape, at the start
      // of a shift.
      return const Failure<Session>(ErrorCode.internalError);
    }
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
  /// The caller must not make the local wipe conditional on this succeeding — see
  /// [LoginDataProvider.logout].
  Future<Result<void>> revokeSessionOnServer() async {
    final response = await dataProvider.logout();
    if (response.isSuccess) return const Success<void>(null);
    return _toFailure<void>(response);
  }

  /// Maps an unsuccessful response onto the shared error vocabulary.
  ///
  /// A transport failure carries no error code, so it is distinguished here rather than by
  /// catching exceptions — [RestClient] already converts socket, timeout, and
  /// malformed-reply faults into [ApiResponse.transportFailure], so every outcome arrives on
  /// one path.
  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: (response.body['error'] as Map<String, Object?>?)?[
          'businessRule'] as String?,
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
      // Derived from the server's *interval* rather than an absolute server timestamp. The
      // handset clock may be hours out — that is the premise of this whole app — but the
      // fifteen minutes the token is good for is still fifteen minutes of elapsed time.
      expiresAt: _clock.nowUtc().add(Duration(seconds: expiresIn)),
      user: parsedUser,
    );
  }
}
