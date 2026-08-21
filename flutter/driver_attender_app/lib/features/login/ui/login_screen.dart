import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/login_error_text.dart';
import '../widgets/phone_entry_form.dart';
import '../widgets/session_ended_notice.dart';
import '../widgets/sign_in_scaffold.dart';

/// Step one of sign-in: the driver's mobile number.
///
/// Holds no state and makes no decisions. It renders [LoginState] and dispatches what the
/// driver did; the bloc decides everything else (CODING_STANDARDS_FLUTTER.md §Layering).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SignInScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.signedOutReason != null)
                SessionEndedNotice(reason: state.signedOutReason!),
              PhoneEntryForm(
                initialValue: state.phone,
                isSubmitting: state.isSubmitting,
                onSubmit: (phone) => context
                    .read<LoginBloc>()
                    .add(LoginPhoneSubmitted(phone)),
              ),
              if (state.error != null)
                LoginErrorText(
                  code: state.error!,
                  messageKey: state.errorMessageKey,
                ),
            ],
          ),
        );
      },
    );
  }
}
