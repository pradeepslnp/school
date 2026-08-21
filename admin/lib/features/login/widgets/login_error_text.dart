import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';

/// Renders a sign-in failure.
///
/// Maps an [ErrorCode] to something an operator can act on. The mapping lives in the widget
/// layer because it is a presentation decision — *what happened* was settled in the
/// repository; this is only *how to say it*.
///
/// **Known gap:** these are string literals, which BR-CFG-005 forbids and
/// CODING_STANDARDS_FLUTTER.md §Localisation enforces with a lint. This project has no
/// `flutter_localizations` setup, and neither does the driver or parent app — introducing a
/// one-off mechanism here would create a fourth pattern to migrate later. Every string in
/// this file is written to be replaced by [messageKey], which the API already supplies and
/// this widget already receives. The same note stands in the driver app's
/// `login_error_text.dart`; the two should be resolved together when localisation lands.
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
                _message,
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _message => switch (code) {
    // Deliberately identical for an unknown address and a wrong password. The API does
    // not distinguish them, because distinguishing them would let anyone enumerate the
    // staff of a named school (AUTHENTICATION_API.md).
    ErrorCode.authCredentialsInvalid =>
      'Those details were not recognised. Check the email address and password.',
    ErrorCode.authAccountLocked =>
      'This account is locked after too many failed attempts. Contact your platform '
          'administrator to unlock it.',
    // Says what to do and roughly when, because the alternative is an operator retrying
    // immediately and extending their own lockout window (BR-IAM-011).
    ErrorCode.rateLimitExceeded =>
      'Too many sign-in attempts. Wait a minute, then try again.',
    ErrorCode.validationRequiredFieldMissing =>
      'Enter both your email address and your password.',
    ErrorCode.validationInvalidFormat ||
    ErrorCode.validationFailed => 'Check the details you entered.',
    // Named as a connection problem, not a failure, and it distinguishes the two things
    // an operator can actually check.
    ErrorCode.dependencyUnavailable =>
      'The Guardian API could not be reached. Check your connection, then try again.',
    ErrorCode.authSessionRevoked || ErrorCode.authRefreshReuseDetected =>
      'That session has ended. Sign in again.',
    // Everything else, including a code this build predates. Says plainly that the
    // problem is not the operator's to fix, and who can fix it.
    _ =>
      'Sign-in is not working right now. Contact your platform administrator.',
  };
}
