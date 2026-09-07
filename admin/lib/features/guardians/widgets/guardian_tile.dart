import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/guardian_models.dart';

/// One parent as the student-detail panel shows them: who they are, how the school reaches
/// them, and — as small chips — the rights that decide what they may do. "Can collect" is the
/// one that matters for safety, so it reads in the platform's safe/positive colour when held.
class GuardianTile extends StatelessWidget {
  const GuardianTile({super.key, required this.guardian});

  final StudentGuardian guardian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relationshipLabel = guardianRelationshipLabel(context.l10n, guardian.relationshipType);

    return ListTile(
      key: Key('guardian_tile_${guardian.linkId}'),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(_initials(), style: theme.textTheme.bodyMedium),
      ),
      title: Row(
        children: [
          Flexible(child: Text(guardian.displayName)),
          if (guardian.isPrimary) ...[
            const SizedBox(width: AdminSpacing.sm),
            _Chip(label: context.l10n.guardianTilePrimaryChip, color: theme.colorScheme.primary),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AdminSpacing.xs),
          Text(context.l10n.guardianTileRelationshipAndPhone(relationshipLabel, guardian.phone)),
          const SizedBox(height: AdminSpacing.sm),
          Wrap(
            spacing: AdminSpacing.sm,
            runSpacing: AdminSpacing.xs,
            children: [
              if (guardian.canAuthoriseHandover)
                _Chip(label: context.l10n.guardianTileCanCollectChip, color: context.status.safe)
              else
                _Chip(
                  label: context.l10n.guardianTileCannotCollectChip,
                  color: context.status.warning,
                ),
              if (guardian.canReceiveNotifications)
                _Chip(
                  label: context.l10n.guardianTileNotifiedChip,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              if (guardian.canDeclareAbsence)
                _Chip(
                  label: context.l10n.guardianTileCanReportAbsenceChip,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              _Chip(
                label: guardian.hasLogin
                    ? context.l10n.guardianTileCanSignInChip
                    : context.l10n.guardianTileNoSignInYetChip,
                color: guardian.hasLogin
                    ? context.status.safe
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  String _initials() {
    final f = guardian.firstName.isNotEmpty ? guardian.firstName[0] : '';
    final l = guardian.lastName.isNotEmpty ? guardian.lastName[0] : '';
    final initials = (f + l).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AdminSpacing.xs),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
