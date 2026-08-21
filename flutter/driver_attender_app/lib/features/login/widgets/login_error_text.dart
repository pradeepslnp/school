import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';

/// Renders a sign-in failure.
///
/// Maps an [ErrorCode] to something a driver standing beside a bus can act on. The mapping
/// lives in the widget layer because it is a presentation decision — *what happened* was
/// settled in the repository; this is only *how to say it*.
///
/// **Known gap:** these are string literals, which BR-CFG-005 forbids and
/// CODING_STANDARDS_FLUTTER.md §Localisation enforces with a lint. This app has no
/// `flutter_localizations` setup yet — no other screen in it does either — so introducing a
/// one-off mechanism here would create a second pattern to migrate later. Every string in
/// this file is written to be replaced by [Failure.messageKey], which the API already
/// supplies and this widget already receives.
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
                _message,
                style: theme.textTheme.bodyMedium?.copyWith(color: critical),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _message => switch (code) {
        // Deliberately identical for an unknown number and a wrong code. The API does not
        // distinguish them, because distinguishing them would let anyone enumerate the staff
        // of a named school (AUTHENTICATION_API.md).
        ErrorCode.authCredentialsInvalid =>
          'That code was not correct. Check it and try again.',
        ErrorCode.authOtpExpired =>
          'That code has expired. Ask for a new one.',
        ErrorCode.authOtpAlreadyUsed =>
          'That code has already been used. Ask for a new one.',
        ErrorCode.authAccountLocked =>
          'This account is locked after too many attempts. Call the transport office.',
        ErrorCode.rateLimitExceeded =>
          'Too many attempts. Wait a minute, then try again.',
        // Named as a connection problem, not a failure, and it says the obvious next step.
        // A driver seeing "something went wrong" in a depot with no signal has been told
        // nothing.
        ErrorCode.dependencyUnavailable =>
          'No connection. Move to where you have signal and try again.',
        ErrorCode.validationRequiredFieldMissing ||
        ErrorCode.validationInvalidFormat ||
        ErrorCode.validationFailed =>
          'Check the details you entered.',
        // Everything else, including a code this build predates. Says plainly that the
        // problem is not the driver's to fix, and who can fix it.
        _ => 'Sign-in is not working right now. Call the transport office.',
      };
}
