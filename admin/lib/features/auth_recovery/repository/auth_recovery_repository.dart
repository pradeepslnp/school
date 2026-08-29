import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/auth_recovery_data_provider.dart';

/// Turns account-recovery transport into domain outcomes (ADR-0012).
///
/// The blocs depend on this, never on [AuthRecoveryDataProvider] directly — matching every other
/// repository in this console, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class AuthRecoveryRepository {
  AuthRecoveryRepository({required this.dataProvider});

  final AuthRecoveryDataProvider dataProvider;

  Future<Result<void>> acceptInvitation({required String token, required String password}) async {
    return _outcome(await dataProvider.acceptInvitation(token: token, password: password));
  }

  /// Requests a reset link. Succeeds whenever the server accepted the request — which it does
  /// regardless of whether the address exists, so a `Success` here means "we asked", not "an
  /// account was found". The screen says so.
  Future<Result<void>> requestPasswordReset({required String email}) async {
    return _outcome(await dataProvider.requestPasswordReset(email: email));
  }

  Future<Result<void>> confirmPasswordReset({
    required String email,
    required String otp,
    required String password,
  }) async {
    return _outcome(
        await dataProvider.confirmPasswordReset(email: email, otp: otp, password: password));
  }

  Result<void> _outcome(ApiResponse response) {
    if (response.isSuccess) {
      return const Success<void>(null);
    }
    if (response.isTransportFailure) {
      return const Failure<void>(ErrorCode.dependencyUnavailable);
    }
    return Failure<void>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: response.errorBusinessRule,
    );
  }
}
