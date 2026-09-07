import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/l10n_extensions.dart';
import '../bloc/login_bloc.dart';
import 'login_error_text.dart';

/// Step one: the guardian's phone number.
///
/// Emits events and renders state. It decides nothing — whether the number is submittable
/// is [LoginState.isPhoneSubmittable], not a rule written here.
class PhoneEntryForm extends StatelessWidget {
  const PhoneEntryForm({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.loginHeading, style: theme.textTheme.titleLarge),
            const SizedBox(height: GuardianSpacing.sm),
            Text(
              context.l10n.loginInstructions,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: GuardianSpacing.lg),
            TextField(
              key: const Key('login_phone_field'),
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              enabled: !state.isSubmitting,
              decoration: InputDecoration(
                labelText: context.l10n.loginMobileNumberLabel,
                border: const OutlineInputBorder(),
                // No hardcoded example number: format varies by region and a sample from
                // the wrong country reads as an error (ADR-0007).
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              onChanged: (value) =>
                  context.read<LoginBloc>().add(LoginPhoneChanged(value)),
              onSubmitted: (_) =>
                  context.read<LoginBloc>().add(const LoginOtpRequested()),
            ),
            LoginErrorText(failure: state.failure),
            const SizedBox(height: GuardianSpacing.lg),
            FilledButton(
              key: const Key('login_request_otp_button'),
              onPressed: state.isPhoneSubmittable
                  ? () =>
                        context.read<LoginBloc>().add(const LoginOtpRequested())
                  : null,
              child: state.isSubmitting
                  ? const SizedBox(
                      height: AppSizeConstants.inlineSpinnerSize,
                      width: AppSizeConstants.inlineSpinnerSize,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.loginSendCodeButton),
            ),
          ],
        );
      },
    );
  }
}
