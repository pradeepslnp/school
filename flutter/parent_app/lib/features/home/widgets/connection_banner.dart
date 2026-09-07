import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';

/// States that the screen is showing cached data, and how old it is.
///
/// The parent app is a read surface and deliberately not offline-first (ADR-0008), so being
/// offline is a display problem — but only if the display is honest about it. Cached state
/// presented as current is the failure BR-TRACK-003 exists to prevent, and PARENT_APP.md
/// requires "Not connected · last updated 07:44" rather than a blank screen.
///
/// Warning, not critical: the parent has lost their view of the child, not the child. The
/// critical treatment stays reserved for genuine safety events
/// (docs/05-ui/DESIGN_SYSTEM.md).
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.lastUpdatedAt, this.onRetry});

  /// When the shown data was last successfully fetched. Null when nothing has loaded.
  final SchoolTime? lastUpdatedAt;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final statusColors = context.status;
    final updated = lastUpdatedAt;
    final message = updated == null
        ? context.l10n.connectionBannerNoData
        : context.l10n.connectionBannerLastUpdated(updated.timeOfDay);

    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: GuardianSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: GuardianSpacing.md,
          vertical: GuardianSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: statusColors.warningSurface,
          borderRadius: BorderRadius.circular(GuardianRadius.md),
          border: Border.all(color: statusColors.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: AppSizeConstants.iconMd, color: statusColors.warning),
            const SizedBox(width: GuardianSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySmall
                    ?.copyWith(color: context.colors.onSurface),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: GuardianSpacing.sm),
              TextButton(onPressed: onRetry, child: Text(context.l10n.retryButton)),
            ],
          ],
        ),
      ),
    );
  }
}
