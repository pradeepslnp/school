import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/l10n_extensions.dart';
import '../bloc/login_bloc.dart';
import 'login_error_text.dart';

/// Step two: the code sent by SMS.
class OtpEntryForm extends StatefulWidget {
  const OtpEntryForm({super.key});

  @override
  State<OtpEntryForm> createState() => _OtpEntryFormState();
}

class _OtpEntryFormState extends State<OtpEntryForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LoginBloc, LoginState>(
      // The BLoC clears the code when it can never succeed; the field follows so the
      // guardian is not left staring at digits that are already dead.
      listenWhen: (previous, current) =>
          previous.otp != current.otp && current.otp.isEmpty,
      listener: (context, state) => _controller.clear(),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.otpHeading, style: theme.textTheme.titleLarge),
            const SizedBox(height: GuardianSpacing.sm),
            Text(
              context.l10n.otpSentTo(state.phone),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: GuardianSpacing.lg),
            TextField(
              key: const Key('login_otp_field'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              enabled: !state.isSubmitting,
              // Lets the platform fill the code straight from the SMS, removing the
              // most error-prone step of the flow.
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: InputDecoration(
                labelText: context.l10n.otpCodeLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.sms_outlined),
              ),
              onChanged: (value) =>
                  context.read<LoginBloc>().add(LoginOtpChanged(value)),
              onSubmitted: (_) =>
                  context.read<LoginBloc>().add(const LoginOtpSubmitted()),
            ),
            LoginErrorText(failure: state.failure),
            const SizedBox(height: GuardianSpacing.lg),
            FilledButton(
              key: const Key('login_verify_button'),
              onPressed: state.isOtpSubmittable
                  ? () =>
                      context.read<LoginBloc>().add(const LoginOtpSubmitted())
                  : null,
              child: state.isSubmitting
                  ? const SizedBox(
                      height: AppSizeConstants.inlineSpinnerSize,
                      width: AppSizeConstants.inlineSpinnerSize,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.otpVerifyButton),
            ),
            const SizedBox(height: GuardianSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => context
                          .read<LoginBloc>()
                          .add(const LoginPhoneEditRequested()),
                  child: Text(context.l10n.otpEntryChangeNumberButton),
                ),
                TextButton(
                  key: const Key('login_resend_button'),
                  onPressed:
                      state.isSubmitting || !state.canResendAt(DateTime.now().toUtc())
                          ? null
                          : () => context
                              .read<LoginBloc>()
                              .add(const LoginOtpResendRequested()),
                  child: Text(context.l10n.otpEntrySendNewCodeButton),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
