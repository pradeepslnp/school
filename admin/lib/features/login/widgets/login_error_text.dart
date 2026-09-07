import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';

/// Renders a sign-in failure.
///
/// Maps an [ErrorCode] to something an operator can act on. The mapping lives in the widget
/// layer because it is a presentation decision — *what happened* was settled in the
/// repository; this is only *how to say it*.
///
/// Copy is now bundled and localised (ADR-0013), resolved through [context]'s
/// `AppLocalizations` rather than a literal. [messageKey] — the API's own localisation key —
/// is still carried through unused: it targets the backend-driven `CFG-006` resource this ADR
/// is an interim step ahead of, not this console's bundled ARB. The two are expected to
/// converge when `CFG-006` ships (see ADR-0013's Reversal Cost).
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
    final color = context.status.critical;

    return Semantics(
      // Assertive, because the message replaces nothing on screen and appears after the
      // operator has already looked away from the form to the button
      // (ACCESSIBILITY.md §Operable).
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AdminSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colour is never the only signal — the icon carries the same meaning to a
            // reader with a color-vision deficiency (DESIGN_SYSTEM.md §Principles).
            Icon(Icons.error_outline, size: 20, color: color),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text(
                _message(context),
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message(BuildContext context) {
    final l10n = context.l10n;
    return switch (code) {
      // Deliberately identical for an unknown address and a wrong password. The API does
      // not distinguish them, because distinguishing them would let anyone enumerate the
      // staff of a named school (AUTHENTICATION_API.md).
      ErrorCode.authCredentialsInvalid => l10n.loginErrorCredentialsInvalid,
      ErrorCode.authAccountLocked => l10n.loginErrorAccountLocked,
      // Says what to do and roughly when, because the alternative is an operator retrying
      // immediately and extending their own lockout window (BR-IAM-011).
      ErrorCode.rateLimitExceeded => l10n.loginErrorRateLimitExceeded,
      ErrorCode.validationRequiredFieldMissing => l10n.loginErrorValidationRequiredField,
      ErrorCode.validationInvalidFormat ||
      ErrorCode.validationFailed => l10n.errorValidationCheckDetails,
      // Named as a connection problem, not a failure, and it distinguishes the two things
      // an operator can actually check.
      ErrorCode.dependencyUnavailable => l10n.errorApiUnreachable,
      ErrorCode.authSessionRevoked || ErrorCode.authRefreshReuseDetected => l10n.errorSessionEnded,
      // Everything else, including a code this build predates. Says plainly that the
      // problem is not the operator's to fix, and who can fix it.
      _ => l10n.loginErrorGenericFailure,
    };
  }
}
