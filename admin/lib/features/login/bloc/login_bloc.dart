import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_manager.dart';
import '../repository/login_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Sign-in for a member of school or platform staff.
///
/// Depends on a repository and the session manager — never on a data provider. That is what
/// lets this be tested with no HTTP and no fake server (CODING_STANDARDS_FLUTTER.md
/// §Layering).
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required LoginRepository repository,
    required SessionManager sessionManager,
    SignOutReason? signedOutReason,
  })  : _repository = repository,
        _sessionManager = sessionManager,
        super(LoginState(signedOutReason: signedOutReason)) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginMethodChanged>(_onMethodChanged);
    on<EmailOtpRequested>(_onEmailOtpRequested);
    on<EmailOtpSubmitted>(_onEmailOtpSubmitted);
    on<EmailOtpRestarted>(_onEmailOtpRestarted);
  }

  final LoginRepository _repository;

  /// Adopting the new session happens here, not in the widget.
  ///
  /// The screen's only job afterwards is to stop being on screen, which it does by observing
  /// [SessionManager.statusStream] like the rest of the console — so there is exactly one
  /// place that knows what "signed in" means, and one place the router listens to.
  final SessionManager _sessionManager;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final email = event.email.trim();
    final password = event.password;

    // The only check made here is that something was entered. Whether the address is
    // well-formed and whether the credentials are correct are the server's decisions
    // (BR-IAM-001) — a pattern hardcoded here would reject valid addresses and would be a
    // second implementation of a rule that already exists (ENGINEERING_PRINCIPLES.md §6).
    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(
        error: ErrorCode.validationRequiredFieldMissing,
        clearSignedOutReason: true,
      ));
      return;
    }

    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      // They are signing in again; the explanation for the last session ending has done its
      // job and should not follow them through the rest of the flow.
      clearSignedOutReason: true,
    ));

    final result = await _repository.signIn(email: email, password: password);

    switch (result) {
      case Success<Session>(:final value):
        // Adopt first, then settle this screen's state. The router reacts to the session
        // manager, so by the time the sign-in screen stops submitting it is already being
        // replaced — the operator never sees an idle form flash before the console appears.
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

  /// Switching method resets the code step: a half-finished code entry from a previous attempt
  /// must not survive into a fresh one.
  void _onMethodChanged(LoginMethodChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(
      useEmailCode: event.useEmailCode,
      codeSent: false,
      codeEmail: '',
      clearError: true,
      clearSignedOutReason: true,
    ));
  }

  Future<void> _onEmailOtpRequested(
    EmailOtpRequested event,
    Emitter<LoginState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty) {
      emit(state.copyWith(
        error: ErrorCode.validationRequiredFieldMissing,
        clearSignedOutReason: true,
      ));
      return;
    }

    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSignedOutReason: true,
    ));

    final result = await _repository.requestEmailOtp(email: email);

    switch (result) {
      case Success<void>():
        // Advances whether or not the address has an account — the server answers identically
        // either way, and advancing only for real accounts would leak which ones exist.
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          codeSent: true,
          codeEmail: email,
        ));

      case Failure(:final code, :final messageKey):
        // In practice only a transport failure or throttling: the endpoint reports nothing
        // account-specific.
        emit(state.copyWith(
          isSubmitting: false,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }

  Future<void> _onEmailOtpSubmitted(
    EmailOtpSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final otp = event.otp.trim();
    if (otp.isEmpty || state.codeEmail.isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.signInWithEmailOtp(
      email: state.codeEmail,
      otp: otp,
    );

    switch (result) {
      case Success<Session>(:final value):
        // Adopt first, then settle — see _onSubmitted for why.
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

  void _onEmailOtpRestarted(EmailOtpRestarted event, Emitter<LoginState> emit) {
    emit(state.copyWith(codeSent: false, codeEmail: '', clearError: true));
  }
}
