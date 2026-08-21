import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../../../core/session/session_manager.dart';

/// Which half of the sign-in the driver is on.
enum LoginStep { enteringPhone, enteringCode }

/// The whole screen, including its loading and error conditions.
///
/// One state class rather than a family of them (CODING_STANDARDS_FLUTTER.md §Layering).
/// Every field the screen renders is here, so there is no combination the widget can be
/// handed that it has not been written for — an untested error condition becomes a blank
/// screen in production, and this screen's blank state is a driver who cannot start a shift.
class LoginState extends Equatable {
  const LoginState({
    this.step = LoginStep.enteringPhone,
    this.phone = '',
    this.isSubmitting = false,
    this.error,
    this.errorMessageKey,
    this.codeResent = false,
    this.signedOutReason,
  });

  final LoginStep step;

  /// Retained across the step change so the code screen can show which number it went to,
  /// and so going back to correct a typo does not clear the field.
  final String phone;

  final bool isSubmitting;

  /// The last failure, or null. An [ErrorCode], never a raw string — the UI decides how to
  /// say it, and a server-supplied display string would be in the wrong language anyway
  /// (BR-CFG-005).
  final ErrorCode? error;

  /// The API's localisation key for [error], when it supplied one.
  final String? errorMessageKey;

  /// A replacement code was just sent. Acknowledged in the UI, because a resend that looks
  /// like nothing happened gets tapped repeatedly, and the endpoint is rate limited per
  /// number.
  final bool codeResent;

  /// Why the previous session ended, when it ended on its own.
  ///
  /// A driver whose session was revoked mid-shift is looking at a sign-in screen they did
  /// not ask for. Without this they would reasonably assume the app had crashed and lost
  /// their trip; the revocation is the one thing that explains it (BR-IAM-007). Cleared as
  /// soon as they start signing in again.
  final SignOutReason? signedOutReason;

  bool get canSubmit => !isSubmitting;

  LoginState copyWith({
    LoginStep? step,
    String? phone,
    bool? isSubmitting,
    ErrorCode? error,
    String? errorMessageKey,
    bool? codeResent,
    bool clearError = false,
    bool clearSignedOutReason = false,
  }) {
    return LoginState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey:
          clearError ? null : (errorMessageKey ?? this.errorMessageKey),
      codeResent: codeResent ?? this.codeResent,
      signedOutReason: clearSignedOutReason ? null : signedOutReason,
    );
  }

  @override
  List<Object?> get props => [
        step,
        phone,
        isSubmitting,
        error,
        errorMessageKey,
        codeResent,
        signedOutReason,
      ];
}
