import 'package:equatable/equatable.dart';

/// What the person at the console did.
///
/// Never what the app should do next. An event named `Show…`, `Navigate…`, or `SetError…`
/// means a decision moved back into the widget (CODING_STANDARDS_FLUTTER.md §Layering).
sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const [];
}

/// The operator submitted the sign-in form.
///
/// Both values travel on the event rather than being accumulated in [LoginState], matching
/// the driver and parent apps. That is not only convention: `flutter_bloc` suppresses an
/// emitted state equal to the current one, so a secret deliberately excluded from equality
/// — as a password must be, since observers print states — would be silently dropped
/// somewhere between the two keystrokes that differ only by it. Carrying it on the event
/// keeps the credential out of any object that is retained, compared, or logged.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;

  final String password;

  /// [password] is deliberately absent. Equality feeds `flutter_bloc`'s transition logging
  /// and any `BlocObserver` a future build adds; a password in a browser console is a
  /// password disclosed (CODING_STANDARDS_FLUTTER.md §Security).
  @override
  List<Object?> get props => [email];

  @override
  String toString() => 'LoginSubmitted(email: $email, password: <redacted>)';
}

/// The operator switched between signing in with a password and with an emailed code
/// (IAM-001, ADR-0012).
final class LoginMethodChanged extends LoginEvent {
  const LoginMethodChanged(this.useEmailCode);

  final bool useEmailCode;

  @override
  List<Object?> get props => [useEmailCode];
}

/// The operator asked for a one-time code to be emailed to [email].
final class EmailOtpRequested extends LoginEvent {
  const EmailOtpRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// The operator submitted the emailed code. The address is held in [LoginState] from the
/// request step, so only the code travels here.
///
/// [otp] is excluded from equality for the same reason a password is — it is a credential, and
/// state transitions are logged (see [LoginSubmitted]).
final class EmailOtpSubmitted extends LoginEvent {
  const EmailOtpSubmitted(this.otp);

  final String otp;

  @override
  List<Object?> get props => const [];

  @override
  String toString() => 'EmailOtpSubmitted(otp: <redacted>)';
}

/// The operator went back from the code step to re-enter their address.
final class EmailOtpRestarted extends LoginEvent {
  const EmailOtpRestarted();
}
