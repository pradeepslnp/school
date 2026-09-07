import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n_extensions.dart';
import '../../../utils/utils.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, required this.phone, required this.onVerified});

  final String phone;
  final void Function() onVerified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.otpAppBarTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.gutter,
              vertical: GuardianSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.otpHeading, style: theme.textTheme.titleLarge),
                  const SizedBox(height: GuardianSpacing.sm),
                  Text(
                    context.l10n.otpSentTo(phone),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: GuardianSpacing.lg),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.otpCodeLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: GuardianSpacing.lg),
                  FilledButton(
                    onPressed: onVerified,
                    child: Text(context.l10n.otpVerifyButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
