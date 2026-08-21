import 'package:flutter/material.dart';

import '../../../app/theme.dart';
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
      appBar: AppBar(title: const Text('Enter code')),
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
                  Text('Enter the code', style: theme.textTheme.titleLarge),
                  const SizedBox(height: GuardianSpacing.sm),
                  Text(
                    'We sent a code to $phone.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: GuardianSpacing.lg),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: GuardianSpacing.lg),
                  FilledButton(
                    onPressed: onVerified,
                    child: const Text('Verify'),
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
