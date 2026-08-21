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
