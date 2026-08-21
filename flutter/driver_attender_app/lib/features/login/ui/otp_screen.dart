import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/login_error_text.dart';
import '../widgets/otp_entry_form.dart';
import '../widgets/sign_in_scaffold.dart';

/// Step two of sign-in: the one-time code.
///
/// A separate screen from [LoginScreen], driven by the same bloc, rather than a second half
/// of one widget. The two steps have different failure vocabularies — a bad number and a bad
/// code are not the same problem — and keeping them apart is what stops the code step
/// inheriting the number step's error state.
///
/// Reached by [LoginState.step] rather than by pushing a route: there is no back gesture off
/// this screen, only the explicit "Change number" control. A driver who swipes back mid-OTP
/// and loses the number they just typed has been given a system affordance that does the
/// wrong thing.
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final bloc = context.read<LoginBloc>();

        return SignInScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OtpEntryForm(
                phone: state.phone,
                isSubmitting: state.isSubmitting,
                codeResent: state.codeResent,
                onSubmit: (otp) => bloc.add(LoginOtpSubmitted(otp)),
                onResend: () => bloc.add(const LoginCodeResendRequested()),
                onChangeNumber: () =>
                    bloc.add(const LoginNumberChangeRequested()),
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
