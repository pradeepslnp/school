import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// The secondary screens a parent reaches from the dashboard.
///
/// Secondary is the operative word: the child cards answer "is my child fine?" without a
/// tap, and these sit below them (docs/05-ui/PARENT_APP.md).
///
/// Journey history (P-05) and notifications (P-08) live in the bottom tab bar (Journeys,
/// Alerts) rather than here — they are places a parent returns to, not one-off actions.
///
/// **A null callback means the action is not available to this guardian.** Screen access is
/// permission-gated (SCREEN_INVENTORY.md) — absence declaration needs
/// `PERM-ABSENCE-DECLARE`, pickup persons needs `PERM-PICKUP-PERSON-MANAGE` and the
/// handover right (BR-GRD-006) — and this widget shows nothing it cannot open. Deciding
/// *which* rights the guardian holds belongs to the session, not to a widget
/// (ENGINEERING_PRINCIPLES.md §8).
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    super.key,
    this.onDeclareAbsence,
    this.onManagePickupPersons,
  });

  /// P-06 · `PERM-ABSENCE-DECLARE`
  final VoidCallback? onDeclareAbsence;

  /// P-07 · `PERM-PICKUP-PERSON-MANAGE`
  final VoidCallback? onManagePickupPersons;

  bool get _hasAny => onDeclareAbsence != null || onManagePickupPersons != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GuardianSpacing.md,
        GuardianSpacing.md,
        GuardianSpacing.md,
        GuardianSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: context.texts.titleMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: GuardianSpacing.sm),
          // Wrap rather than a fixed grid: the tiles reflow at 200% text scale and under a
          // 40% longer translation instead of overflowing (docs/05-ui/ACCESSIBILITY.md).
          Wrap(
            spacing: GuardianSpacing.sm,
            runSpacing: GuardianSpacing.sm,
            children: [
              if (onDeclareAbsence != null)
                _QuickAction(
                  icon: Icons.event_busy_outlined,
                  label: 'Declare absence',
                  onPressed: onDeclareAbsence!,
                ),
              if (onManagePickupPersons != null)
                _QuickAction(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Pickup persons',
                  onPressed: onManagePickupPersons!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        // The theme's 48px floor still applies; this only relaxes the horizontal half so a
        // short label does not reserve a 48px-wide block of empty space.
        minimumSize: const Size(0, kMinimumTouchTarget),
        foregroundColor: context.colors.onSurface,
        side: BorderSide(color: context.colors.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: GuardianSpacing.md),
      ),
    );
  }
}
