import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../widgets/freshness_indicator.dart';
import '../../../widgets/journey_status_chip.dart';
import '../repository/models/child_status.dart';
import 'child_avatar.dart';

/// One child's current status.
///
/// The primary unit of the home screen. Answers "where is my child" in a glance, without
/// a tap (docs/05-ui/PARENT_APP.md).
///
/// Tone matters here as much as content: [PRODUCT_PRINCIPLES.md §2] asks for prompt,
/// specific, *calm* information. Ordinary progress is stated plainly; only genuine safety
/// states escalate visually.
class ChildStatusCard extends StatelessWidget {
  const ChildStatusCard({
    super.key,
    required this.status,
    this.onTrackPressed,
    this.onDetailsPressed,
  });

  final ChildStatus status;

  /// Invoked when the parent asks to track the bus.
  ///
  /// Supplying it does not guarantee the control appears: tracking is trip-scoped
  /// (BR-TRACK-001) and this widget enforces that itself rather than trusting callers.
  final VoidCallback? onTrackPressed;

  final VoidCallback? onDetailsPressed;

  @override
  Widget build(BuildContext context) {
    final isCritical = status.journeyState.isCritical;

    // Enforced here, not only at the call site. A business rule that depends on every
    // caller remembering it is a rule that will eventually be broken by a new screen
    // (ENGINEERING_PRINCIPLES.md §6).
    final canOfferTracking = status.canTrack && onTrackPressed != null;

    return Card(
      // A critical state is outlined, not merely tinted. It must survive a glance in
      // sunlight on a low-quality screen.
      shape: isCritical
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GuardianRadius.lg),
              side: BorderSide(
                color: context.status.critical,
                width: AppSizeConstants.emphasisBorderWidth,
              ),
            )
          : null,
      child: InkWell(
        onTap: onDetailsPressed,
        borderRadius: BorderRadius.circular(GuardianRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(GuardianSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChildAvatar(name: status.displayName),
                  const SizedBox(width: GuardianSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.displayName,
                          style: context.texts.titleLarge,
                        ),
                        if (status.className != null)
                          Text(
                            status.className!,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GuardianSpacing.sm),
              // The chip sits on its own line rather than beside the name: at 200% text
              // scale a name and a chip cannot share a row without one of them being
              // clipped, and neither is the one to lose.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: JourneyStatusChip(state: status.journeyState),
              ),
              const SizedBox(height: GuardianSpacing.sm),
              _DetailLine(status: status),
              if (_arrivalEstimate != null) ...[
                const SizedBox(height: GuardianSpacing.xs),
                Text(
                  _arrivalEstimate!,
                  style: context.texts.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
              if (status.canTrack) ...[
                const SizedBox(height: GuardianSpacing.sm),
                FreshnessIndicator(
                  age: status.positionFreshness,
                  isStale: status.isPositionStaleReported,
                ),
              ],
              if (canOfferTracking) ...[
                const SizedBox(height: GuardianSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onTrackPressed,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Track bus'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The arrival estimate, shown only once the child is aboard.
  ///
  /// Always framed as an estimate and carrying the age of the data it was computed from
  /// (BR-TRACK-006). An unqualified "Arriving 08:15" is a promise the platform cannot keep,
  /// and a parent who plans around it and is wrong blames the app — correctly.
  String? get _arrivalEstimate {
    if (status.journeyState != JourneyState.onBoard) return null;
    final eta = status.estimatedArrival?.timeOfDay;
    if (eta == null) return null;

    final age = status.positionFreshness;
    if (age == null) return 'Arriving at school about $eta · estimate';
    return 'Arriving at school about $eta · estimated ${_age(age)} ago';
  }

  static String _age(Duration duration) {
    if (duration.inMinutes < 1) return '${duration.inSeconds}s';
    if (duration.inHours < 1) return '${duration.inMinutes} min';
    return '${duration.inHours} h';
  }
}

/// The sentence under the heading: what happened, where, and when.
///
/// Specificity is the point — "Boarded Bus 12 at Green Park at 07:42" tells a parent
/// everything; "Status updated" tells them nothing and invites a phone call to the office.
class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.status});

  final ChildStatus status;

  @override
  Widget build(BuildContext context) {
    final text = _compose();
    if (text == null) return const SizedBox.shrink();

    return Text(text, style: context.texts.bodyMedium);
  }

  String? _compose() {
    final vehicle = status.vehicleDisplayName;
    final stop = status.stopName;
    final at = status.lastEventAt?.timeOfDay;
    final eta = status.estimatedArrival?.timeOfDay;
    final next = status.nextDepartureAt?.timeOfDay;

    return switch (status.journeyState) {
      // Calm, not empty. Absence of news is itself communicated
      // (docs/05-ui/PARENT_APP.md) — a blank card reads as a failed load.
      JourneyState.atRest => next != null
          ? 'At school. Next bus at $next.'
          : 'At school. No bus scheduled for the rest of today.',
      JourneyState.absent =>
        'You marked ${status.displayName} as not travelling today.',
      JourneyState.scheduled => [
          if (vehicle != null) '$vehicle is scheduled',
          if (stop != null) 'from $stop',
          if (eta != null) 'at about $eta',
        ].join(' ').trim(),
      JourneyState.awaitingBoarding => [
          if (vehicle != null) '$vehicle is on the way',
          if (stop != null) 'to $stop',
          // Always framed as an estimate, with no false precision (BR-TRACK-006).
          if (eta != null) '· arriving about $eta',
        ].join(' ').trim(),
      JourneyState.onBoard => [
          'Boarded',
          ?vehicle,
          if (stop != null) 'at $stop',
          if (at != null) 'at $at',
        ].join(' ').trim(),
      JourneyState.arrivedAtSchool =>
        at != null ? 'Arrived at school at $at.' : 'Arrived at school.',
      JourneyState.handedOver => [
          'Handed over',
          if (stop != null) 'at $stop',
          if (at != null) 'at $at',
        ].join(' ').trim(),
      // Factual, not accusatory. The bus may have been early, or the child may be with
      // the other parent — the app does not know which.
      JourneyState.noShow => [
          'Did not board',
          ?vehicle,
          if (stop != null) 'at $stop',
          if (at != null) '· bus departed $at',
        ].join(' ').trim(),
      // The school is already acting on this before the parent opens the app
      // (BR-SAFE-001); saying so is what makes the message bearable.
      JourneyState.unaccounted =>
        'No record of ${status.displayName} getting off the bus. '
            'The school has been alerted and is checking now.',
      // Names the app as the limitation, and routes the parent to someone who does know.
      // "Something went wrong" would leave them deciding whether to drive to the school.
      JourneyState.unknown =>
        "This version of the app cannot read ${status.displayName}'s current status. "
            'Update the app, or contact the school office to check.',
    };
  }
}
