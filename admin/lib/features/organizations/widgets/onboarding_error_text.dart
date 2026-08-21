import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';

/// Renders an onboarding failure. Mirrors `LoginErrorText`'s split between *what happened*
/// (settled in the repository) and *how to say it* (this widget).
///
/// Same known gap as `LoginErrorText`: string literals in place of [messageKey], which
/// BR-CFG-005 wants localised. Left unresolved for the same reason — this console has no
/// localisation mechanism yet, and inventing a one-off here would be a second thing to
/// migrate later.
class OnboardingErrorText extends StatelessWidget {
  const OnboardingErrorText({super.key, required this.code, this.messageKey});

  final ErrorCode code;
  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = context.status.critical;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AdminSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    ErrorCode.orgCodeAlreadyExists =>
      'That organization code is already in use. Choose another — codes cannot be changed '
          'once operational data exists (BR-TEN-007).',
    ErrorCode.schoolCodeAlreadyExists =>
      'That school code is already used within this organization. Choose another.',
    ErrorCode.staffEmployeeCodeExists =>
      'That employee code is already used at this school. Choose another.',
    ErrorCode.validationRequiredFieldMissing => 'Fill in every required field.',
    ErrorCode.validationInvalidFormat ||
    ErrorCode.validationFailed => 'Check the details you entered.',
    ErrorCode.authPermissionDenied =>
      'Your account does not have permission to create organizations.',
    ErrorCode.dependencyUnavailable =>
      'The Guardian API could not be reached. Check your connection, then try again.',
    ErrorCode.authSessionRevoked || ErrorCode.authRefreshReuseDetected =>
      'That session has ended. Sign in again.',
    _ => 'That could not be saved right now. Try again shortly.',
  };
}
