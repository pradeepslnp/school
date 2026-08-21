import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';

/// Renders a student-register failure. Mirrors `OnboardingErrorText`'s split between *what
/// happened* (settled in the repository) and *how to say it* (this widget).
///
/// Its own widget rather than reusing the organizations one, matching `LoginErrorText`: the
/// messages here are about admission numbers and enrolment, and a shared widget accumulating
/// every feature's copy is how one screen ends up telling an operator about organization codes.
///
/// Same known gap as the others: string literals in place of [messageKey], which BR-CFG-005
/// wants localised. Left unresolved for the same reason — this console has no localisation
/// mechanism yet, and inventing a one-off here would be a second thing to migrate later.
class StudentErrorText extends StatelessWidget {
  const StudentErrorText({super.key, required this.code, this.messageKey});

  final ErrorCode code;
  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Not `context.status.critical`: that colour is reserved for genuine safety events
    // (DESIGN_SYSTEM.md), and spending it on a duplicate admission number erodes the one
    // signal that must never be ignored. The error colour from the scheme says "you need to
    // fix this" without saying "a child is in danger".
    final color = theme.colorScheme.error;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AdminSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon as well as colour — colour is never the only signal (DESIGN_SYSTEM.md).
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
        ErrorCode.studentAdmissionNoExists =>
          'That admission number is already used at this school. Check whether the student is '
              'already enrolled before creating a second record for them.',
        ErrorCode.studentNotFound =>
          'That student could not be found. They may have been moved to another school.',
        ErrorCode.studentNotActive =>
          'That student is not on the active roll, so they cannot be assigned to transport.',
        ErrorCode.validationRequiredFieldMissing => 'Fill in every required field.',
        ErrorCode.validationInvalidFormat ||
        ErrorCode.validationFailed =>
          'Check the details you entered.',
        ErrorCode.authPermissionDenied =>
          'Your account does not have permission to manage students.',
        ErrorCode.authScopeDenied =>
          'That student is outside the schools your account covers.',
        ErrorCode.dependencyUnavailable =>
          'The Guardian API could not be reached. Check your connection, then try again.',
        ErrorCode.authSessionRevoked ||
        ErrorCode.authRefreshReuseDetected =>
          'That session has ended. Sign in again.',
        _ => 'That could not be saved right now. Try again shortly.',
      };
}
