import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/auth_recovery_repository.dart';

/// Which step of the reset the screen is on (ADR-0012).
enum PasswordResetPhase {
  /// Enter the email address to receive a code.
  enterEmail,

  /// Enter the emailed code and choose a new password.
  enterCodeAndPassword,

  /// Done — the password was changed.
  done,
}

/// The operator asked for a reset code for [email].
final class ResetCodeRequested extends Equatable {
  const ResetCodeRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// The operator submitted the emailed code and a new password.
final class ResetSubmitted extends Equatable {
  const ResetSubmitted({required this.otp, required this.newPassword});

  final String otp;
  final String newPassword;

  @override
  List<Object?> get props => [otp, newPassword];
}

/// Marker supertype so the bloc can take both events.
sealed class PasswordResetEvent {
  const PasswordResetEvent();
}

final class _RequestCode extends PasswordResetEvent {
  const _RequestCode(this.email);
  final String email;
}

final class _Submit extends PasswordResetEvent {
  const _Submit(this.otp, this.newPassword);
  final String otp;
  final String newPassword;
}

/// State of the forgot-password / reset screen.
class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.phase = PasswordResetPhase.enterEmail,
    this.email = '',
    this.isSubmitting = false,
    this.error,
    this.errorMessageKey,
  });

  final PasswordResetPhase phase;

  /// The address the code was sent to — remembered from step one so step two can show it and the
  /// confirm call can pass it (the code alone does not identify the account).
  final String email;

  final bool isSubmitting;
  final ErrorCode? error;
  final String? errorMessageKey;

  PasswordResetState copyWith({
    PasswordResetPhase? phase,
    String? email,
    bool? isSubmitting,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return PasswordResetState(
      phase: phase ?? this.phase,
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [phase, email, isSubmitting, error, errorMessageKey];
}

/// Drives the two-step self-service password reset (ADR-0012, IAM-010): request a code, then submit
/// the code with a new password.
///
/// Requesting a code always advances to the code step whatever the server says about the address —
/// the endpoint is deliberately non-enumerating, so the screen cannot reveal whether an account
/// exists either. Only a transport failure keeps the person on step one to retry.
class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  PasswordResetBloc({required AuthRecoveryRepository repository})
      : _repository = repository,
        super(const PasswordResetState()) {
    on<_RequestCode>(_onRequestCode);
    on<_Submit>(_onSubmit);
  }

  final AuthRecoveryRepository _repository;

  /// Public entry points — the screen adds these; the private events above are the internal shape.
  void requestCode(String email) => add(_RequestCode(email));

  void submit({required String otp, required String newPassword}) =>
      add(_Submit(otp, newPassword));

  Future<void> _onRequestCode(_RequestCode event, Emitter<PasswordResetState> emit) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true, clearError: true, email: event.email));

    final result = await _repository.requestPasswordReset(email: event.email);
    switch (result) {
      case Success<void>():
        emit(state.copyWith(
          isSubmitting: false,
          phase: PasswordResetPhase.enterCodeAndPassword,
          clearError: true,
        ));
      case Failure<void>(:final code, :final messageKey):
        // Only a transport failure reaches here — the endpoint reports nothing account-specific.
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onSubmit(_Submit event, Emitter<PasswordResetState> emit) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.confirmPasswordReset(
      email: state.email,
      otp: event.otp,
      password: event.newPassword,
    );
    switch (result) {
      case Success<void>():
        emit(state.copyWith(isSubmitting: false, phase: PasswordResetPhase.done, clearError: true));
      case Failure<void>(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
