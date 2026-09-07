import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';

/// Renders a sign-in failure.
///
/// Maps an [ErrorCode] to something a driver standing beside a bus can act on. The mapping
/// lives in the widget layer because it is a presentation decision — *what happened* was
/// settled in the repository; this is only *how to say it*.
///
/// **Known gap:** the messages come from [_message] below, a `switch` on [ErrorCode], rather
/// than from [messageKey] via `AppLocalizations`. ADR-0013 covers bundled client copy, not
/// the server-driven `resource_key` design `messageKey` is meant for (`CFG-006`, still
/// unbuilt) — so this widget's strings are ARB-backed and switchable between English and
/// Kannada like every other string in this app, but keyed on the client-side [ErrorCode]
/// enum rather than on the key the API sends. [messageKey] is kept in the signature,
/// unused, for the same reason as before: when `CFG-006` lands, this widget changes and
/// nothing that builds it does.
class LoginErrorText extends StatelessWidget {
  const LoginErrorText({super.key, required this.code, this.messageKey});

  final ErrorCode code;

  /// The API's localisation key, carried through unused for now. Present in the signature
  /// deliberately: when localisation lands, this widget changes and nothing that builds it
  /// does.
  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final critical = context.status.critical;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: DriverSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 22, color: critical),
            const SizedBox(width: DriverSpacing.sm),
            Expanded(
              child: Text(
                _message(context.l10n),
                style: theme.textTheme.bodyMedium?.copyWith(color: critical),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message(AppLocalizations l10n) => switch (code) {
        // Deliberately identical for an unknown number and a wrong code. The API does not
        // distinguish them, because distinguishing them would let anyone enumerate the staff
        // of a named school (AUTHENTICATION_API.md).
        ErrorCode.authCredentialsInvalid => l10n.errorInvalidCode,
        ErrorCode.authOtpExpired => l10n.errorOtpExpired,
        ErrorCode.authOtpAlreadyUsed => l10n.errorOtpAlreadyUsed,
        ErrorCode.authAccountLocked => l10n.errorAccountLocked,
        ErrorCode.rateLimitExceeded => l10n.errorRateLimited,
        // Named as a connection problem, not a failure, and it says the obvious next step.
        // A driver seeing "something went wrong" in a depot with no signal has been told
        // nothing.
        ErrorCode.dependencyUnavailable => l10n.errorNoConnection,
        ErrorCode.validationRequiredFieldMissing ||
        ErrorCode.validationInvalidFormat ||
        ErrorCode.validationFailed =>
          l10n.errorValidationFailed,
        // Everything else, including a code this build predates. Says plainly that the
        // problem is not the driver's to fix, and who can fix it.
        _ => l10n.errorSignInUnavailable,
      };
}
