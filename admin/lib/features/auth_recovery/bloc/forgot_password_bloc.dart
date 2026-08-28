import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/auth_recovery_repository.dart';

/// The operator asked for a reset link for [email].
final class ForgotPasswordSubmitted extends Equatable {
  const ForgotPasswordSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// State of the forgot-password screen.
class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.isSubmitting = false,
    this.isSent = false,
    this.error,
    this.errorMessageKey,
  });

  final bool isSubmitting;

  /// The request was accepted. The screen shows the deliberately generic "if that account exists,
  /// we've sent a link" confirmation — a positive result reveals nothing about whether the address
  /// has an account (OWASP anti-enumeration).
  final bool isSent;

  final ErrorCode? error;
  final String? errorMessageKey;

  ForgotPasswordState copyWith({
    bool? isSubmitting,
    bool? isSent,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSent: isSent ?? this.isSent,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isSubmitting, isSent, error, errorMessageKey];
}

/// Requests a password-reset link (ADR-0012).
///
/// Only a transport failure is surfaced as an error — the server accepts the request whether or not
/// the address has an account, so any non-transport response is treated as sent.
class ForgotPasswordBloc extends Bloc<ForgotPasswordSubmitted, ForgotPasswordState> {
  ForgotPasswordBloc({required AuthRecoveryRepository repository})
      : _repository = repository,
        super(const ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  final AuthRecoveryRepository _repository;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.requestPasswordReset(email: event.email);

    switch (result) {
      case Success<void>():
        emit(state.copyWith(isSubmitting: false, isSent: true, clearError: true));
      case Failure<void>(:final code, :final messageKey):
        // In practice only dependencyUnavailable — the endpoint does not report account-level
        // failures. Shown so a person on a dropped connection knows to try again rather than
        // assuming a link is on its way.
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
