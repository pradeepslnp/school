import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/session/session_manager.dart';

/// Explains a sign-in screen the operator did not ask for.
///
/// Shown only when the previous session ended on its own. Without it, an operator dropped
/// back to sign-in mid-task would reasonably conclude the console had crashed and lost their
/// work — and would go looking for a fault that does not exist (BR-IAM-007).
///
/// Rendered in the warning tone rather than the critical one: `statusCritical` is reserved
/// for genuine safety events, and spending it on a session expiry erodes the one signal that
/// must never be ignored (DESIGN_SYSTEM.md §Status colors).
class SessionEndedNotice extends StatelessWidget {
  const SessionEndedNotice({super.key, required this.reason});

  final SignOutReason reason;

  @override
  Widget build(BuildContext context) {
    // A deliberate sign-out needs no explanation; the operator knows why they are here.
    if (reason == SignOutReason.userRequested) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = context.status.warning;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AdminSpacing.lg),
        padding: const EdgeInsets.all(AdminSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(AdminSpacing.xs),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20, color: color),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(child: Text(_message, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }

  String get _message => switch (reason) {
    // Names the two real causes rather than saying "for security reasons", which tells
    // an operator nothing and makes a deactivated account look like a bug.
    SignOutReason.revokedByServer =>
      'Your session was ended by the platform. This happens when an account is '
          'deactivated or a session is revoked.',
    SignOutReason.refreshFailed =>
      'Your session expired and could not be renewed. Sign in to continue.',
    SignOutReason.userRequested => '',
  };
}
