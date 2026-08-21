import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../repository/models/child_status.dart';

/// The full-width banner for a child who is not accounted for.
///
/// **The only element permitted to dominate the home screen** (docs/05-ui/PARENT_APP.md).
/// It exists for NTF-SAFE-01 and NTF-HAND-05 — the events where a parent must act now.
///
/// Keeping it rare is the whole design. A banner that also appeared for a late bus would
/// teach parents to scroll past it, and the one time it mattered they would.
class CriticalAlertBanner extends StatelessWidget {
  const CriticalAlertBanner({
    super.key,
    required this.status,
    this.onCallSchool,
    this.onViewDetail,
  });

  final ChildStatus status;

  /// Calling the school is the action, not tracking the bus: BR-SAFE-001 says staff are
  /// already searching, and a parent watching a map cannot help.
  final VoidCallback? onCallSchool;

  final VoidCallback? onViewDetail;

  @override
  Widget build(BuildContext context) {
    final statusColors = context.status;
    final message =
        '${status.displayName} has not been accounted for. The school has been alerted '
        'and staff are checking now.';

    return Semantics(
      // Assertive: this is the one class of change that may interrupt whatever the screen
      // reader is saying (docs/05-ui/ACCESSIBILITY.md).
      liveRegion: true,
      container: true,
      label: 'Urgent. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GuardianSpacing.md),
        decoration: BoxDecoration(
          // Solid, not tinted: this is the one banner in the app allowed to dominate the
          // screen (docs/05-ui/PARENT_APP.md), and it needs to read as unmistakably
          // different at a glance in sunlight on a low-quality screen — a tint next to a
          // white card is not that.
          color: statusColors.critical,
          borderRadius: BorderRadius.circular(GuardianRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: AppSizeConstants.iconLg,
                ),
                const SizedBox(width: GuardianSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTION NEEDED NOW',
                        style: context.texts.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: GuardianSpacing.xs),
                      Text(
                        'Not yet accounted for',
                        style: context.texts.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: GuardianSpacing.xs),
                      Text(
                        message,
                        style: context.texts.bodyMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onCallSchool != null || onViewDetail != null) ...[
              const SizedBox(height: GuardianSpacing.md),
              // A Wrap, not a Row: at 200% text scale two buttons side by side overflow,
              // and a safety action that is clipped off-screen is a safety action that does
              // not exist.
              Wrap(
                spacing: GuardianSpacing.sm,
                runSpacing: GuardianSpacing.sm,
                children: [
                  if (onCallSchool != null)
                    FilledButton.icon(
                      onPressed: onCallSchool,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: statusColors.critical,
                      ),
                      icon: const Icon(Icons.call),
                      label: const Text('Call the school'),
                    ),
                  if (onViewDetail != null)
                    OutlinedButton(
                      onPressed: onViewDetail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text('See what happened'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
