import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/login_repository.dart';
import '../repository/models/session.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Login decisions.
///
/// Holds every rule about what is submittable, what a failure means, and when the guardian
/// may retry. The UI reads state and emits events — it decides nothing
/// (ENGINEERING_PRINCIPLES.md §8).
///
/// Depends on [LoginRepository], never on the data provider, so it is tested with a fake
/// repository and no HTTP.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this.repository, DateTime Function()? clock})
    : _now = clock ?? (() => DateTime.now().toUtc()),
      super(const LoginState()) {
    on<LoginPhoneChanged>(_onPhoneChanged);
    on<LoginOtpRequested>(_onOtpRequested);
    on<LoginOtpChanged>(_onOtpChanged);
    on<LoginOtpSubmitted>(_onOtpSubmitted);
    on<LoginOtpResendRequested>(_onResendRequested);
    on<LoginPhoneEditRequested>(_onPhoneEditRequested);
  }

  final LoginRepository repository;

  /// Injected so resend timing is testable without waiting in real time.
  final DateTime Function() _now;

  /// Matches the server's resend throttle closely enough to keep the guardian from
  /// triggering a 429 they cannot interpret.
  static const _resendCooldown = Duration(seconds: 30);

  /// Whether the entered code can never succeed, however it is retyped.
  static bool _codeIsDead(ErrorCode code) =>
      code == ErrorCode.authOtpExpired || code == ErrorCode.authOtpAlreadyUsed;

  void _onPhoneChanged(LoginPhoneChanged event, Emitter<LoginState> emit) {
    // Typing clears the previous error: leaving it visible while the field changes reads
    // as though the new input has already been rejected.
    emit(state.copyWith(phone: event.phone, clearFailure: true));
  }

  void _onOtpChanged(LoginOtpChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(otp: event.otp, clearFailure: true));
  }

  void _onPhoneEditRequested(
    LoginPhoneEditRequested event,
    Emitter<LoginState> emit,
  ) {
    emit(
      state.copyWith(
        step: LoginStep.enteringPhone,
        otp: '',
        clearFailure: true,
      ),
    );
  }

  Future<void> _onOtpRequested(
    LoginOtpRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isPhoneSubmittable) return;
    await _requestOtp(emit);
  }

  Future<void> _onResendRequested(
    LoginOtpResendRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (state.isSubmitting || !state.canResendAt(_now())) return;
    await _requestOtp(emit);
  }

  Future<void> _requestOtp(Emitter<LoginState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true));

    final result = await repository.requestOtp(phone: state.phone.trim());

    switch (result) {
      case Success<void>():
        emit(
          state.copyWith(
            // Advances even though the API does not confirm the number is registered —
            // it deliberately never says, and revealing it here would undo that.
            step: LoginStep.enteringOtp,
            isSubmitting: false,
            otp: '',
            resendAvailableAt: _now().add(_resendCooldown),
          ),
        );
      case Failure<void>(:final code, :final messageKey, :final businessRule):
        emit(
          state.copyWith(
            isSubmitting: false,
            failure: Failure<void>(
              code,
              messageKey: messageKey,
              businessRule: businessRule,
            ),
          ),
        );
    }
  }

  Future<void> _onOtpSubmitted(
    LoginOtpSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isOtpSubmittable) return;

    emit(state.copyWith(isSubmitting: true, clearFailure: true));

    final result = await repository.verifyOtp(
      phone: state.phone.trim(),
      otp: state.otp.trim(),
    );

    switch (result) {
      case Success<Session>(:final value):
        emit(
          state.copyWith(
            step: LoginStep.authenticated,
            isSubmitting: false,
            session: value,
          ),
        );
      case Failure<Session>(
        :final code,
        :final messageKey,
        :final businessRule,
      ):
        emit(
          state.copyWith(
            isSubmitting: false,
            // An expired or already-used code can never succeed. Clearing the field stops
            // the guardian retyping the same dead code; a wrong code is left in place so
            // they can correct one digit.
            otp: _codeIsDead(code) ? '' : state.otp,
            failure: Failure<void>(
              code,
              messageKey: messageKey,
              businessRule: businessRule,
            ),
          ),
        );
    }
  }
}
