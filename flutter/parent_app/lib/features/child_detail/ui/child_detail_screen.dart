import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/l10n_extensions.dart';
import '../../../utils/utils.dart';
import '../../../widgets/freshness_indicator.dart';
import '../../../widgets/journey_status_chip.dart';
import '../repository/models/child_detail.dart';
import '../widgets/journey_leg_tile.dart';

/// P-03 — one child's full picture.
///
/// Renders state it is given; it does not fetch (ENGINEERING_PRINCIPLES.md §8). Reached from
/// the dashboard card, and — for a child not currently on a trip — offers no map, matching
/// PARENT_APP.md P-04: live tracking is trip-scoped, not a permanently available screen.
class ChildDetailScreen extends StatelessWidget {
  const ChildDetailScreen({
    super.key,
    required this.displayName,
    this.detail,
    this.isLoading = false,
    this.loadFailure,
    this.onRefresh,
    this.onTrack,
    this.onShowPickupCode,
  });

  final String displayName;
  final ChildDetail? detail;
  final bool isLoading;
  final String? loadFailure;
  final Future<void> Function()? onRefresh;

  /// Null when tracking is unavailable for this child right now (BR-TRACK-001).
  final VoidCallback? onTrack;

  /// Opens P-12 — the QR / numeric code shown to the attendant at drop
  /// (docs/05-ui/PARENT_APP.md § P-12). Always supplied by the route: scope
  /// (`can_authorise_handover`, BR-GRD-006) is checked server-side when the code is
  /// requested, not guessed here, so a guardian without the right still opens the screen and
  /// sees why it refused rather than never finding the button.
  final VoidCallback? onShowPickupCode;

  /// Opens P-12 — the QR / numeric code shown to the attendant at drop
  /// (docs/05-ui/PARENT_APP.md § P-12). Null when the guardian does not hold
  /// `can_authorise_handover` for this child (BR-GRD-006); the screen itself still opens on
  /// tap and explains the refusal, since scope is checked server-side, not guessed here.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final detail = this.detail;

    if (isLoading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadFailure != null && detail == null) {
      return _Message(detail: loadFailure!, onRetry: onRefresh);
    }

    if (detail == null) {
      return _Message(detail: context.l10n.childDetailNoDetailAvailable);
    }

    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(GuardianSpacing.md),
      children: [
        ReadableWidth(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(GuardianSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.className != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: GuardianSpacing.sm),
                      child: Text(
                        detail.className!,
                        style: context.texts.bodyMedium
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ),
                  JourneyStatusChip(state: detail.currentState),
                  if (detail.canTrack) ...[
                    const SizedBox(height: GuardianSpacing.sm),
                    FreshnessIndicator(
                      age: detail.positionFreshness,
                      isStale: detail.isPositionStaleReported,
                    ),
                  ],
                  if (onTrack != null) ...[
                    const SizedBox(height: GuardianSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onTrack,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(context.l10n.trackBusButton),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: GuardianSpacing.lg),
        ReadableWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GuardianSpacing.sm),
            child: Text(context.l10n.childDetailTodayLabel, style: context.texts.titleLarge),
          ),
        ),
        ReadableWidth(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GuardianSpacing.md,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < detail.legs.length; i++) ...[
                    if (i > 0) const Divider(),
                    JourneyLegTile(leg: detail.legs[i]),
                  ],
                  if (detail.legs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: GuardianSpacing.md,
                      ),
                      child: Text(
                        context.l10n.childDetailNoTripsToday,
                        style: context.texts.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (onShowPickupCode != null) ...[
          const SizedBox(height: GuardianSpacing.lg),
          ReadableWidth(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onShowPickupCode,
                icon: const Icon(Icons.qr_code_2_outlined),
                label: Text(context.l10n.childDetailShowPickupCodeButton),
              ),
            ),
          ),
        ],
      ],
    );

    if (onRefresh == null) return content;
    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.detail, this.onRetry});

  final String detail;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GuardianSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSizeConstants.emptyStateIcon,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: GuardianSpacing.md),
            Text(detail, style: context.texts.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: GuardianSpacing.lg),
              FilledButton.tonal(
                onPressed: () => onRetry!(),
                child: Text(context.l10n.tryAgainButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
