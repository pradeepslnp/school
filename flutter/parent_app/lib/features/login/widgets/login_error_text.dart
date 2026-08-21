import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';

/// Renders a login failure as something the guardian can act on.
///
/// Maps the error **code** to wording. The server's message string is never displayed:
/// it is not localised to the guardian's language and may leak internal detail
/// (BR-CFG-005, ENGINEERING_PRINCIPLES.md §12).
class LoginErrorText extends StatelessWidget {
  const LoginErrorText({super.key, required this.failure});

  final Failure<void>? failure;

  @override
  Widget build(BuildContext context) {
    final current = failure;
    if (current == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? GuardianColors.criticalDark : GuardianColors.critical;

    return Padding(
      padding: const EdgeInsets.only(top: GuardianSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: AppSizeConstants.iconMd, color: color),
          const SizedBox(width: GuardianSpacing.sm),
          Expanded(
            child: Text(
              messageFor(current.code),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// Wording per error code.
  ///
  /// Exposed so tests assert the mapping without pumping a widget tree.
  static String messageFor(ErrorCode code) => switch (code) {
        ErrorCode.authCredentialsInvalid =>
          'That code is not correct. Please check and try again.',
        ErrorCode.authOtpExpired =>
          'That code has expired. Tap “Send a new code” to get another.',
        ErrorCode.authOtpAlreadyUsed =>
          'That code has already been used. Tap “Send a new code”.',
        ErrorCode.authAccountLocked =>
          'This account is locked. Please contact the school office.',
        // Tells the guardian to wait rather than implying they did something wrong.
        ErrorCode.rateLimitExceeded =>
          'Too many attempts. Please wait a minute before trying again.',
        ErrorCode.dependencyUnavailable =>
          'Cannot reach the school right now. Check your connection and try again.',
        // Anything else, including a code this build predates: one honest, non-technical
        // sentence. An unrecognised code must never surface as a raw string.
        _ => 'Something went wrong. Please try again.',
      };
}
