import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import '../domain/manifest_models.dart';

/// One child on the manifest, with the single action their current state allows.
///
/// Never two actions at once. An attendant with a queue of children at the door needs the right
/// button under their thumb without reading, and a row offering both "on" and "off" is a row where
/// the wrong one gets pressed.
class ManifestChildTile extends StatelessWidget {
  const ManifestChildTile({
    super.key,
    required this.child,
    required this.onBoard,
    required this.onAlight,
  });

  final ManifestChild child;
  final VoidCallback onBoard;
  final VoidCallback onAlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: DriverSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(DriverSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.studentName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (child.className != null) child.className!,
                      if (child.expectedStopName != null) child.expectedStopName!,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DriverSpacing.xs),
                  _StatusChip(child: child),
                ],
              ),
            ),
            const SizedBox(width: DriverSpacing.sm),
            _action(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, AppLocalizations l10n) {
    if (child.status.canBoard) {
      return FilledButton(
        key: Key('manifest_board_${child.studentId}'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(96, kDriverTouchTarget),
        ),
        onPressed: onBoard,
        child: Text(l10n.manifestBoardAction),
      );
    }

    if (child.status.canAlight) {
      return FilledButton.tonal(
        key: Key('manifest_alight_${child.studentId}'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(96, kDriverTouchTarget),
        ),
        onPressed: onAlight,
        child: Text(l10n.manifestAlightAction),
      );
    }

    // Absent or no-show: nothing for the crew to do, and no button to press by accident.
    return const SizedBox(width: 96);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.child});

  final ManifestChild child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final (label, tone) = switch (child.status) {
      ManifestEntryStatus.expected => (l10n.manifestStatusExpected, theme.colorScheme.outline),
      ManifestEntryStatus.boarded => (l10n.manifestStatusBoarded, context.status.safe),
      ManifestEntryStatus.alighted => (l10n.manifestStatusAlighted, theme.colorScheme.outline),
      ManifestEntryStatus.noShow => (l10n.manifestStatusNoShow, context.status.warning),
      ManifestEntryStatus.absent => (l10n.manifestStatusAbsent, theme.colorScheme.outline),
      ManifestEntryStatus.unknown => (l10n.manifestStatusUnknown, context.status.warning),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: tone)),
        ),
        if (child.pendingSync) ...[
          const SizedBox(width: DriverSpacing.xs),
          // Not an error. It says the record is safely on this device and the server has not
          // acknowledged it yet — which on a bus is the normal state, not a problem.
          Icon(
            Icons.schedule_outlined,
            size: 16,
            // The shared theme has a colour for exactly this state — queued, not failed.
            color: context.status.pendingSync,
            semanticLabel: l10n.manifestPendingSync,
          ),
        ],
      ],
    );
  }
}
