part of 'login_bloc.dart';

/// Things the user did. Never things the app should do.
///
/// An event named `ShowError` or `NavigateHome` would be the UI issuing instructions,
/// which puts the decision back in the widget. Events report intent; the BLoC decides
/// (ENGINEERING_PRINCIPLES.md §8).
sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const [];
}

/// The guardian edited the phone field.
final class LoginPhoneChanged extends LoginEvent {
  const LoginPhoneChanged(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

/// The guardian asked for a code.
final class LoginOtpRequested extends LoginEvent {
  const LoginOtpRequested();
}

/// The guardian edited the code field.
final class LoginOtpChanged extends LoginEvent {
  const LoginOtpChanged(this.otp);

  final String otp;

  @override
  List<Object?> get props => [otp];
}

/// The guardian submitted the code.
final class LoginOtpSubmitted extends LoginEvent {
  const LoginOtpSubmitted();
}

/// The guardian asked for a new code.
final class LoginOtpResendRequested extends LoginEvent {
  const LoginOtpResendRequested();
}

/// The guardian went back to correct the number they typed.
final class LoginPhoneEditRequested extends LoginEvent {
  const LoginPhoneEditRequested();
}
