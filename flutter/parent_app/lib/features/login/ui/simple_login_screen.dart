import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/l10n_extensions.dart';
import '../../../utils/utils.dart';
import 'otp_screen.dart';

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key, required this.onAuthenticated});

  final void Function(String sessionJson) onAuthenticated;

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _requestOtp() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isSubmitting = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phone: _phoneController.text,
          onVerified: () {
            widget.onAuthenticated(
              '{"user":"parent","phone":"${_phoneController.text}"}',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loginHeading)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.gutter,
              vertical: GuardianSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.simpleLoginParentHeading, style: theme.textTheme.titleLarge),
                  const SizedBox(height: GuardianSpacing.sm),
                  Text(
                    context.l10n.loginInstructions,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: GuardianSpacing.lg),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.l10n.loginMobileNumberLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: GuardianSpacing.lg),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _requestOtp,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: AppSizeConstants.inlineSpinnerSize,
                            width: AppSizeConstants.inlineSpinnerSize,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.loginSendCodeButton),
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
