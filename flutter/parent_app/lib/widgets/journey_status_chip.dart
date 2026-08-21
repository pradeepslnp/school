import 'package:flutter/material.dart';

import '../app/app_size_constants.dart';
import '../app/theme.dart';
import '../core/domain.dart';

/// How a journey state is spoken and shown: icon, color, label.
///
/// A single value rather than three loose ones, because these three must never be assembled
/// independently — an icon that disagrees with its label is a status a parent cannot trust.
@immutable
class JourneyStatusPresentation {
  const JourneyStatusPresentation({
    required this.icon,
    required this.color,
    required this.surface,
    required this.label,
  });

  final IconData icon;

  /// Foreground: the icon and the label.
  final Color color;

  /// The chip fill. A defined tint, not the foreground at reduced opacity — a translucent
  /// foreground over an unknown background is a contrast ratio nobody has checked.
  final Color surface;

  final String label;
}

/// Icon + label + color for a journey state.
///
/// Shared across every feature that shows a child's status — the dashboard, child detail,
/// the live map, and journey history — so the same state always reads identically wherever
/// it appears (docs/06-development/PROJECT_STRUCTURE.md).
///
/// All three, always. Colour alone excludes parents with color-vision deficiency and is
/// invisible to a screen reader (docs/05-ui/ACCESSIBILITY.md).
class JourneyStatusChip extends StatelessWidget {
  const JourneyStatusChip({super.key, required this.state});

  final JourneyState state;

  @override
  Widget build(BuildContext context) {
    final presentation = describe(state, context.status);

    return Semantics(
      label: presentation.label,
      // The icon and text below carry no information the label does not already state, so
      // the screen reader announces the status once rather than three times.
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GuardianSpacing.sm,
          vertical: GuardianSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: presentation.surface,
          borderRadius: BorderRadius.circular(GuardianRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(presentation.icon, size: AppSizeConstants.iconSm, color: presentation.color),
            const SizedBox(width: GuardianSpacing.xs),
            Flexible(
              child: Text(
                presentation.label,
                style: context.texts.labelMedium?.copyWith(
                  color: presentation.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The vocabulary for a journey state.
  ///
  /// Exposed so the banner, the card, and any future surface describe a state identically.
  /// Two screens that word the same state differently are two screens a parent has to
  /// reconcile under stress.
  static JourneyStatusPresentation describe(
    JourneyState state,
    GuardianStatusColors status,
  ) {
    return switch (state) {
      JourneyState.atRest => JourneyStatusPresentation(
        icon: Icons.remove,
        color: status.neutral,
        surface: status.neutralSurface,
        label: 'At school',
      ),
      JourneyState.scheduled => JourneyStatusPresentation(
        icon: Icons.schedule,
        color: status.info,
        surface: status.infoSurface,
        label: 'Bus scheduled',
      ),
      JourneyState.awaitingBoarding => JourneyStatusPresentation(
        icon: Icons.directions_bus,
        color: status.info,
        surface: status.infoSurface,
        label: 'Bus on the way',
      ),
      JourneyState.onBoard => JourneyStatusPresentation(
        icon: Icons.check_circle,
        color: status.safe,
        surface: status.safeSurface,
        label: 'On the bus',
      ),
      JourneyState.arrivedAtSchool => JourneyStatusPresentation(
        icon: Icons.school,
        color: status.safe,
        surface: status.safeSurface,
        label: 'Arrived at school',
      ),
      JourneyState.handedOver => JourneyStatusPresentation(
        icon: Icons.done_all,
        color: status.safe,
        surface: status.safeSurface,
        label: 'Handed over',
      ),
      JourneyState.noShow => JourneyStatusPresentation(
        icon: Icons.error_outline,
        color: status.warning,
        surface: status.warningSurface,
        label: 'Did not board',
      ),
      JourneyState.absent => JourneyStatusPresentation(
        icon: Icons.event_busy,
        color: status.neutral,
        surface: status.neutralSurface,
        label: 'Not travelling today',
      ),
      JourneyState.unaccounted => JourneyStatusPresentation(
        icon: Icons.warning_amber_rounded,
        color: status.critical,
        surface: status.criticalSurface,
        label: 'Not yet accounted for',
      ),
      // Neutral, and says so. DESIGN_SYSTEM.md assigns `statusNeutral` to "not started,
      // absent, unknown" — an unreadable status is reported, not dressed up as a calm one.
      JourneyState.unknown => JourneyStatusPresentation(
        icon: Icons.help_outline,
        color: status.neutral,
        surface: status.neutralSurface,
        label: 'Status unavailable',
      ),
    };
  }
}
