import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_manager.dart';
import '../repository/login_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Sign-in for a driver or attendant.
///
/// Depends on a repository and the session manager — never on a data provider. That is what
/// lets this be tested with no HTTP, no fake server, and no keychain
/// (CODING_STANDARDS_FLUTTER.md §Layering).
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required LoginRepository repository,
    required SessionManager sessionManager,
    SignOutReason? signedOutReason,
  })  : _repository = repository,
        _sessionManager = sessionManager,
        super(LoginState(signedOutReason: signedOutReason)) {
    on<LoginPhoneSubmitted>(_onPhoneSubmitted);
    on<LoginOtpSubmitted>(_onOtpSubmitted);
    on<LoginNumberChangeRequested>(_onNumberChangeRequested);
    on<LoginCodeResendRequested>(_onCodeResendRequested);
  }

  final LoginRepository _repository;

  /// Adopting the new session happens here, not in the widget.
  ///
  /// The screen's only job afterwards is to stop being on screen, which it does by observing
  /// [SessionManager.statusStream] like the rest of the app — so there is exactly one place
  /// that knows what "signed in" means.
  final SessionManager _sessionManager;

  Future<void> _onPhoneSubmitted(
    LoginPhoneSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final phone = event.phone.trim();

    // The only check made here is that something was typed. Phone format is validated
    // against the region profile server-side (ADR-0007, VALIDATION_INVALID_FORMAT), and a
    // pattern hardcoded in the client would reject a valid number the moment the platform
    // opened in a country whose numbering plan it predates.
    if (phone.isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(
      phone: phone,
      isSubmitting: true,
      codeResent: false,
      clearError: true,
      // The driver is signing in again; the explanation for the last session ending has done
      // its job and should not follow them through the rest of the flow.
      clearSignedOutReason: true,
    ));

    final result = await _repository.requestOtp(phone: phone);

    switch (result) {
      case Success():
        emit(state.copyWith(
          step: LoginStep.enteringCode,
          isSubmitting: false,
          clearError: true,
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          isSubmitting: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }

  Future<void> _onOtpSubmitted(
    LoginOtpSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final otp = event.otp.trim();
    if (otp.isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(
      isSubmitting: true,
      codeResent: false,
      clearError: true,
    ));

    final result = await _repository.verifyOtp(phone: state.phone, otp: otp);

    switch (result) {
      case Success<Session>(:final value):
        await _sessionManager.adopt(value);
        emit(state.copyWith(isSubmitting: false, clearError: true));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          isSubmitting: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }

  void _onNumberChangeRequested(
    LoginNumberChangeRequested event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(
      step: LoginStep.enteringPhone,
      codeResent: false,
      clearError: true,
    ));
  }

  Future<void> _onCodeResendRequested(
    LoginCodeResendRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.requestOtp(phone: state.phone);

    switch (result) {
      case Success():
        emit(state.copyWith(isSubmitting: false, codeResent: true));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          isSubmitting: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }
}
