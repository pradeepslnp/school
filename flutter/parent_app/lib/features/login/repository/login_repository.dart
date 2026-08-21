import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/login_data_provider.dart';
import 'models/session.dart';

/// Turns authentication transport into domain outcomes.
///
/// The BLoC depends on this, never on [LoginDataProvider] — so the BLoC can be tested with
/// a fake repository and no HTTP at all, and a transport change never reaches presentation
/// (ENGINEERING_PRINCIPLES.md §4).
///
/// Every path returns a [Result]; nothing throws for an expected failure. A wrong OTP is
/// an ordinary outcome, not an exception.
class LoginRepository {
  LoginRepository({required this.dataProvider});

  final LoginDataProvider dataProvider;

  /// Requests an OTP.
  ///
  /// Succeeds whether or not the number is registered — the API does not say, and neither
  /// does this. See [LoginDataProvider.requestOtp].
  Future<Result<void>> requestOtp({required String phone}) async {
    final response = await dataProvider.requestOtp(phone: phone);
    if (response. isSuccess) return const Success<void>(null);
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
      // A 2xx we cannot read is a contract breach, not a credential problem. Saying
      // "invalid code" here would send the parent round a loop they cannot escape.
      return const Failure<Session>(ErrorCode.internalError);
    }
    return Success<Session>(session);
  }

  /// Maps an unsuccessful response onto the shared error vocabulary.
  ///
  /// A transport failure carries no error code, so it is distinguished here rather than by
  /// catching exceptions — RestClient already converts socket, timeout, and malformed-reply
  /// faults into [ApiResponse.transportFailure], so every outcome arrives on one path.
  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return const Failure(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
    );
  }

  static Session? _parseSession(Map<String, Object?> data) {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final expiresIn = data['expiresIn'] as int?;
    final user = data['user'] as Map<String, Object?>?;

    if (accessToken == null ||
        refreshToken == null ||
        expiresIn == null ||
        user == null) {
      return null;
    }

    final id = user['id'] as String?;
    if (id == null) return null;

    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      // Derived from the server's lifetime rather than a server-supplied absolute time:
      // the device clock may be wrong, but the interval is still trustworthy.
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
      user: AuthenticatedUser(
        id: id,
        firstName: user['firstName'] as String? ?? '',
        lastName: user['lastName'] as String? ?? '',
        preferredLocale: user['preferredLocale'] as String? ?? 'en',
      ),
    );
  }
}
