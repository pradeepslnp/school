import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';

/// Renders an onboarding failure. Mirrors `LoginErrorText`'s split between *what happened*
/// (settled in the repository) and *how to say it* (this widget).
///
/// [messageKey] — the API's own localisation key — is still carried through and still unused:
/// ADR-0013 localises this console's own bundled copy, not the backend-driven `CFG-006`
/// resource this key would resolve against server-side. The two are expected to converge when
/// `CFG-006` ships (see that ADR's Reversal Cost).
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
      ErrorCode.orgCodeAlreadyExists => l10n.onboardingErrorOrgCodeExists,
      ErrorCode.schoolCodeAlreadyExists => l10n.onboardingErrorSchoolCodeExists,
      ErrorCode.orgCannotSuspendOwnOrganization =>
        l10n.onboardingErrorCannotSuspendOwnOrganization,
      ErrorCode.staffEmployeeCodeExists => l10n.onboardingErrorStaffEmployeeCodeExists,
      ErrorCode.staffHasSafetyRecords => l10n.staffErrorHasSafetyRecords,
      ErrorCode.routeMinimumStopsRequired => l10n.routeStopsErrorMinimum,
      ErrorCode.routeGeofenceOutOfBounds => l10n.routeStopsErrorGeofence,
      ErrorCode.routeStopTimesNotIncreasing => l10n.routeStopsErrorTimesNotIncreasing,
      ErrorCode.routeStopNotFound => l10n.routeStopsErrorStale,
      ErrorCode.routeStopHasAssignedStudents => l10n.routeStopsErrorHasAssignedStudents,
      ErrorCode.staffNotFound => l10n.staffErrorNotFound,
      ErrorCode.validationRequiredFieldMissing => l10n.errorValidationRequiredField,
      ErrorCode.validationInvalidFormat ||
      ErrorCode.validationFailed => l10n.errorValidationCheckDetails,
      ErrorCode.authPermissionDenied => l10n.onboardingErrorPermissionDenied,
      ErrorCode.dependencyUnavailable => l10n.errorApiUnreachable,
      ErrorCode.authSessionRevoked || ErrorCode.authRefreshReuseDetected => l10n.errorSessionEnded,
      _ => l10n.errorGenericRetryShortly,
    };
  }
}
