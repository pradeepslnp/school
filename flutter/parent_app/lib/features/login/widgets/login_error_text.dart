import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';

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
              messageFor(current.code, context.l10n),
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
  /// Takes the resolved [AppLocalizations] rather than a [BuildContext] so a caller that
  /// already has one — such as a widget test — need not pump a widget tree just to resolve
  /// it again.
  static String messageFor(ErrorCode code, AppLocalizations l10n) => switch (code) {
        ErrorCode.authCredentialsInvalid => l10n.loginErrorCredentialsInvalid,
        ErrorCode.authOtpExpired => l10n.loginErrorOtpExpired,
        ErrorCode.authOtpAlreadyUsed => l10n.loginErrorOtpAlreadyUsed,
        ErrorCode.authAccountLocked => l10n.loginErrorAccountLocked,
        // Tells the guardian to wait rather than implying they did something wrong.
        ErrorCode.rateLimitExceeded => l10n.loginErrorRateLimited,
        ErrorCode.dependencyUnavailable => l10n.loginErrorDependencyUnavailable,
        // Anything else, including a code this build predates: one honest, non-technical
        // sentence. An unrecognised code must never surface as a raw string.
        _ => l10n.errorGenericTryAgain,
      };
}
