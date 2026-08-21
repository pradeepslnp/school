import 'package:equatable/equatable.dart';

/// What the person at the handset did.
///
/// Never what the app should do next. An event named `Show…`, `Navigate…`, or `SetError…`
/// means a decision moved back into the widget (CODING_STANDARDS_FLUTTER.md §Layering).
sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const [];
}

/// The driver entered their number and asked for a code.
final class LoginPhoneSubmitted extends LoginEvent {
  const LoginPhoneSubmitted(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

/// The driver entered the code they received.
final class LoginOtpSubmitted extends LoginEvent {
  const LoginOtpSubmitted(this.otp);

  final String otp;

  @override
  List<Object?> get props => [otp];
}

/// The driver went back to correct the number.
final class LoginNumberChangeRequested extends LoginEvent {
  const LoginNumberChangeRequested();
}

/// The driver asked for another code.
final class LoginCodeResendRequested extends LoginEvent {
  const LoginCodeResendRequested();
}
