part of 'login_bloc.dart';

/// Which step the guardian is on.
enum LoginStep {
  /// Entering a phone number.
  enteringPhone,

  /// A code has been requested; entering it.
  enteringOtp,

  /// Authenticated.
  authenticated,
}

/// Everything the login UI renders from.
///
/// One state class rather than a hierarchy: the UI needs the phone number *and* the step
/// *and* any error simultaneously, and separate states would force the widget to remember
/// what the previous one held — which is state living in the widget.
final class LoginState extends Equatable {
  const LoginState({
    this.step = LoginStep.enteringPhone,
    this.phone = '',
    this.otp = '',
    this.isSubmitting = false,
    this.failure,
    this.session,
    this.resendAvailableAt,
  });

  final LoginStep step;
  final String phone;
  final String otp;

  /// A request is in flight. The UI disables submission rather than letting a second
  /// request race the first.
  final bool isSubmitting;

  /// Set when the last attempt failed. Carries the error code so the UI can choose
  /// wording; it never carries a server-supplied display string (BR-CFG-005).
  final Failure<void>? failure;

  final Session? session;

  /// When a new code may be requested. Resend is rate-limited server-side; showing a
  /// countdown stops the guardian hammering a button that will be refused.
  final DateTime? resendAvailableAt;

  /// Whether the number looks submittable.
  ///
  /// A length check only. Real validation is the region profile's job server-side
  /// (ADR-0007) — a hardcoded pattern here would reject valid numbers in the next country
  /// the platform sells into.
  bool get isPhoneSubmittable => phone.trim().length >= 8 && !isSubmitting;

  bool get isOtpSubmittable => otp.trim().length >= 4 && !isSubmitting;

  bool canResendAt(DateTime now) =>
      resendAvailableAt == null || now.isAfter(resendAvailableAt!);

  LoginState copyWith({
    LoginStep? step,
    String? phone,
    String? otp,
    bool? isSubmitting,
    Session? session,
    DateTime? resendAvailableAt,
    bool clearFailure = false,
    Failure<void>? failure,
  }) {
    return LoginState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      otp: otp ?? this.otp,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      // Explicit clearing, because `null` in copyWith otherwise means "unchanged" and a
      // stale error would survive the next attempt.
      failure: clearFailure ? null : (failure ?? this.failure),
      session: session ?? this.session,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
    );
  }

  @override
  List<Object?> get props => [
        step,
        phone,
        otp,
        isSubmitting,
        failure?.code,
        session,
        resendAvailableAt,
      ];
}
