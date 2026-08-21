import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/session/session_manager.dart';

/// Explains a sign-in screen the driver did not ask for.
///
/// A session can end without the user doing anything: staff deactivation revokes every
/// session that person holds (BR-IAM-008), and a refresh token detected as reused revokes the
/// whole family including the legitimate one (BR-IAM-009). A driver mid-shift meeting a login
/// screen with no explanation will reasonably conclude the app crashed and lost the trip —
/// and the trip is what they will then stop recording.
class SessionEndedNotice extends StatelessWidget {
  const SessionEndedNotice({super.key, required this.reason});

  final SignOutReason reason;

  @override
  Widget build(BuildContext context) {
    // A user-initiated sign-out needs no explanation: they were there.
    if (reason == SignOutReason.userRequested) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final palette = context.status;
    final color = palette.warning;

    final message = switch (reason) {
      SignOutReason.revokedByServer =>
        'Your session was ended by the school. Sign in again, or call the '
            'transport office if this keeps happening.',
      SignOutReason.refreshFailed =>
        'Your session expired. Sign in again to keep recording this trip.',
      SignOutReason.userRequested => '',
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: DriverSpacing.lg),
        padding: const EdgeInsets.all(DriverSpacing.md),
        decoration: BoxDecoration(
          color: palette.warningSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 22, color: color),
            const SizedBox(width: DriverSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
