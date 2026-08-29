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
}
