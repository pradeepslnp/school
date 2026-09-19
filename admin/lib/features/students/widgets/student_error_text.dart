import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';

/// Renders a student-register failure. Mirrors `OnboardingErrorText`'s split between *what
/// happened* (settled in the repository) and *how to say it* (this widget).
///
/// Its own widget rather than reusing the organizations one, matching `LoginErrorText`: the
/// messages here are about admission numbers and enrolment, and a shared widget accumulating
/// every feature's copy is how one screen ends up telling an operator about organization codes.
///
/// [messageKey] is still carried through unused — see `OnboardingErrorText`'s doc comment for
/// why (ADR-0013 vs. the backend-driven `CFG-006` this key targets).
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
      ErrorCode.studentAdmissionNoExists => l10n.studentErrorAdmissionNoExists,
      ErrorCode.studentNotFound => l10n.studentErrorNotFound,
      ErrorCode.studentNotActive => l10n.studentErrorNotActive,
      ErrorCode.studentHasSafetyRecords => l10n.studentErrorHasSafetyRecords,
      ErrorCode.guardianPhoneInUse => l10n.studentErrorGuardianPhoneInUse,
      ErrorCode.guardianNotFound => l10n.studentErrorGuardianNotFound,
      ErrorCode.validationRequiredFieldMissing => l10n.errorValidationRequiredField,
      ErrorCode.validationInvalidFormat ||
      ErrorCode.validationFailed => l10n.errorValidationCheckDetails,
      ErrorCode.authPermissionDenied => l10n.studentErrorPermissionDenied,
      ErrorCode.authScopeDenied => l10n.studentErrorScopeDenied,
      ErrorCode.dependencyUnavailable => l10n.errorApiUnreachable,
      ErrorCode.authSessionRevoked || ErrorCode.authRefreshReuseDetected => l10n.errorSessionEnded,
      _ => l10n.errorGenericRetryShortly,
    };
  }
}
