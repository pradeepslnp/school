import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../../../core/session/session_manager.dart';

/// The whole sign-in screen, including its loading and error conditions.
///
/// One state class rather than a family of them (CODING_STANDARDS_FLUTTER.md §Layering).
/// Every field the screen renders is here, so there is no combination the widget can be
/// handed that it has not been written for — an untested error condition becomes a blank
/// screen in production, and this screen's blank state is an operator who cannot reach the
/// console during an incident.
///
/// **No credential is held here.** Neither the email nor the password is accumulated in
/// state: the form widget owns its controllers, and both values arrive on [LoginSubmitted].
/// So there is no retained object holding a password to be compared, printed by a bloc
/// observer, or captured in an error report.
class LoginState extends Equatable {
  const LoginState({
    this.isSubmitting = false,
    this.error,
    this.errorMessageKey,
    this.signedOutReason,
    this.useEmailCode = false,
    this.codeSent = false,
    this.codeEmail = '',
  });

  final bool isSubmitting;

  /// Whether the operator chose "email me a code" rather than a password (IAM-001, ADR-0012).
  /// Both methods issue the same session; neither replaces the other.
  final bool useEmailCode;

  /// Whether the code request has been accepted, so the screen shows the code field.
  ///
  /// True even when the address has no account: the request endpoint answers identically either
  /// way, and a screen that advanced only for real accounts would leak exactly what the endpoint
  /// is careful not to (OWASP anti-enumeration).
  final bool codeSent;

  /// The address the code was requested for, remembered from the request step because the
  /// verify call needs it — six digits do not identify an account on their own.
  ///
  /// Not a credential, unlike the code itself, so it is safe to hold in state.
  final String codeEmail;

  /// The last failure, or null. An [ErrorCode], never a raw string — the UI decides how to
  /// say it, and a server-supplied display string would be in the wrong language anyway
  /// (BR-CFG-005).
  final ErrorCode? error;

  /// The API's localisation key for [error], when it supplied one.
  ///
  /// Carried through unused until localisation lands; see `login_error_text.dart`.
  final String? errorMessageKey;

  /// Why the previous session ended, when it ended on its own.
  ///
  /// An operator whose session was revoked mid-incident is looking at a sign-in screen they
  /// did not ask for. Without this they would reasonably assume the console had crashed and
  /// lost their work; the revocation is the one thing that explains it (BR-IAM-007). Cleared
  /// as soon as they start signing in again.
  final SignOutReason? signedOutReason;

  /// Whether a submission may be started.
  ///
  /// Only guards against a second in-flight attempt. Empty fields are *not* checked here:
  /// the control stays enabled and the bloc answers with
  /// [ErrorCode.validationRequiredFieldMissing], because a disabled button gives a screen
  /// reader nothing to activate and no explanation of why — the console must be fully
  /// keyboard operable (ACCESSIBILITY.md §Operable).
  bool get canSubmit => !isSubmitting;

  LoginState copyWith({
    bool? isSubmitting,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
    bool clearSignedOutReason = false,
    bool? useEmailCode,
    bool? codeSent,
    String? codeEmail,
  }) {
    return LoginState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey:
          clearError ? null : (errorMessageKey ?? this.errorMessageKey),
      signedOutReason: clearSignedOutReason ? null : signedOutReason,
      useEmailCode: useEmailCode ?? this.useEmailCode,
      codeSent: codeSent ?? this.codeSent,
      codeEmail: codeEmail ?? this.codeEmail,
    );
  }

  @override
  List<Object?> get props => [
        isSubmitting,
        error,
        errorMessageKey,
        signedOutReason,
        useEmailCode,
        codeSent,
        codeEmail,
      ];
}
