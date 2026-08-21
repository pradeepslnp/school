import 'package:flutter/material.dart';
import 'package:guardian_theme/guardian_theme.dart';

import '../../../app/theme.dart';
import '../../../core/offline/sync_status.dart';

/// Persistent indicator of the outbound queue (D-14).
///
/// Shown on **every** screen of the driver app, not tucked into a settings page. The
/// attendant is the only person positioned to act on a sync problem — by keeping the app
/// open until it clears, or by telling the office — and they can only do that if they can
/// see it (ADR-0008, DRIVER_ATTENDANT_APP.md).
///
/// Offline is a normal condition on a route, not an error. It is reported plainly, without
/// alarm, because alarming the attendant about expected connectivity gaps would train them
/// to ignore the indicator that also reports real problems.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, required this.status, this.onTap});

  final SyncStatus status;

  /// Opens the pending-records list and a manual retry (D-14). Null until that screen
  /// exists — the banner stays truthful either way, and a tap that does nothing would be
  /// worse than a tap that is not offered.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, surface, message) = _describe(context.status);

    return Material(
      color: surface,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          liveRegion: true,
          label: message,
          button: onTap != null,
          // One announcement for the whole banner. Without container + excludeSemantics
          // the icon and text are separate nodes, so a screen-reader user hears the status
          // in fragments — and the composed sentence is the part that carries the meaning.
          container: true,
          excludeSemantics: true,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: DriverSpacing.md,
              vertical: DriverSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: DriverSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontSize: 16,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Icon, foreground, and banner fill for the current queue state.
  ///
  /// [palette] carries each status color already paired with its surface tint, so the fill
  /// is a specified color rather than an opacity applied to the foreground and hoped to
  /// still meet AA.
  (IconData, Color, Color, String) _describe(GuardianStatusColors palette) {
    // Reviewed first: a flagged record needs a human decision and outranks queue state
    // (BR-SAFE-005).
    final needingReview = status.flaggedForReviewCount + status.refusedCount;
    if (needingReview > 0) {
      return (
        Icons.flag_outlined,
        palette.warning,
        palette.warningSurface,
        '$needingReview ${needingReview == 1 ? 'record needs' : 'records need'} review',
      );
    }

    if (status.needsAttention) {
      final n = status.pendingCount;
      return (
        Icons.cloud_off,
        palette.pendingSync,
        palette.pendingSyncSurface,
        // States plainly that nothing is lost — the attendant's real question.
        'Offline · $n ${n == 1 ? 'record' : 'records'} saved on this device, '
            'will send when back in range',
      );
    }

    if (!status.isOnline) {
      return (
        Icons.cloud_off,
        palette.neutral,
        palette.neutralSurface,
        'Offline · nothing waiting to send',
      );
    }

    if (status.hasPendingWork) {
      final n = status.pendingCount;
      return (
        Icons.cloud_upload_outlined,
        palette.info,
        palette.infoSurface,
        'Sending $n ${n == 1 ? 'record' : 'records'}…',
      );
    }

    return (
      Icons.cloud_done_outlined,
      palette.safe,
      palette.safeSurface,
      'All records sent${_sinceLastSync()}',
    );
  }

  /// "· 3 min ago", or nothing if the queue has never been drained on this device.
  ///
  /// Relative rather than a clock time on purpose. BR-CFG-006 requires times to render in
  /// the **school's** timezone, never the device's, and this app has no school configuration
  /// yet — so "15:47" here would be a device-local reading presented as if it were
  /// authoritative. An elapsed interval needs no timezone to be true, and "4 minutes ago" is
  /// closer to the question the attendant is actually asking.
  String _sinceLastSync() {
    final at = status.lastSyncedAt;
    if (at == null) return '';

    // Compared against the device clock, which is fine for an interval: both readings come
    // from the same clock, so its offset from real time cancels out.
    final elapsed = DateTime.now().toUtc().difference(at);
    if (elapsed.isNegative) return '';
    if (elapsed.inMinutes < 1) return ' · just now';
    if (elapsed.inMinutes < 60) return ' · ${elapsed.inMinutes} min ago';
    return ' · ${elapsed.inHours} h ago';
  }
}
