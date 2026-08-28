import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/auth_recovery_repository.dart';

/// Which flow a [SetPasswordBloc] is driving — the two share one bloc because both are "submit a
/// token and a new password, then show done or an error" (ADR-0012).
enum PasswordSetMode {
  /// Accepting an invitation: the account activates.
  acceptInvitation,

  /// Completing a reset: the password is replaced and every session ends.
  resetPassword,
}

/// The operator submitted a new password. The token is fixed for the life of the bloc (it came in
/// the link), so it is not carried on the event.
final class SetPasswordSubmitted extends Equatable {
  const SetPasswordSubmitted(this.password);

  final String password;

  @override
  List<Object?> get props => [password];
}

/// State of the accept-invitation / reset-password screen.
class SetPasswordState extends Equatable {
  const SetPasswordState({
    this.isSubmitting = false,
    this.isDone = false,
    this.error,
    this.errorMessageKey,
  });

  final bool isSubmitting;

  /// The password was set. The screen swaps the form for a "you can sign in now" panel.
  final bool isDone;

  final ErrorCode? error;
  final String? errorMessageKey;

  SetPasswordState copyWith({
    bool? isSubmitting,
    bool? isDone,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return SetPasswordState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isDone: isDone ?? this.isDone,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isSubmitting, isDone, error, errorMessageKey];
}

/// Sets a password from an invitation or reset link (ADR-0012).
///
/// Depends on a repository only — matching every other bloc in this console, so it is tested with
/// no HTTP and no fake server.
class SetPasswordBloc extends Bloc<SetPasswordSubmitted, SetPasswordState> {
  SetPasswordBloc({
    required AuthRecoveryRepository repository,
    required String token,
    required PasswordSetMode mode,
  })  : _repository = repository,
        _token = token,
        _mode = mode,
        super(const SetPasswordState()) {
    on<SetPasswordSubmitted>(_onSubmitted);
  }

  final AuthRecoveryRepository _repository;
  final String _token;
  final PasswordSetMode _mode;

  Future<void> _onSubmitted(
    SetPasswordSubmitted event,
    Emitter<SetPasswordState> emit,
  ) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = switch (_mode) {
      PasswordSetMode.acceptInvitation =>
        await _repository.acceptInvitation(token: _token, password: event.password),
      PasswordSetMode.resetPassword =>
        await _repository.confirmPasswordReset(token: _token, password: event.password),
    };

    switch (result) {
      case Success<void>():
        emit(state.copyWith(isSubmitting: false, isDone: true, clearError: true));
      case Failure<void>(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
