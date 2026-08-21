import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../widgets/journey_status_chip.dart';
import '../repository/models/child_detail.dart';

/// One row of the "Today" section — a single morning or afternoon leg.
class JourneyLegTile extends StatelessWidget {
  const JourneyLegTile({super.key, required this.leg});

  final JourneyLeg leg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GuardianSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizeConstants.timestampColumnWidth,
            child: Text(
              leg.direction == JourneyDirection.morning ? 'Morning' : 'Afternoon',
              style: context.texts.titleMedium,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: JourneyStatusChip(state: leg.state),
                ),
                const SizedBox(height: GuardianSpacing.xs),
                Text(_detail(), style: context.texts.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _detail() {
    final vehicle = leg.vehicleDisplayName;
    final stop = leg.stopName;
    final scheduled = leg.scheduledAt?.timeOfDay;
    final event = leg.eventAt?.timeOfDay;

    final where = [
      if (vehicle != null) vehicle,
      if (stop != null) stop,
    ].join(' · ');

    final when = switch (leg.state) {
      JourneyState.scheduled when scheduled != null => 'Scheduled at $scheduled',
      JourneyState.onBoard when event != null => 'Boarded at $event',
      JourneyState.arrivedAtSchool when event != null => 'Arrived at $event',
      JourneyState.handedOver when event != null => 'Handed over at $event',
      JourneyState.noShow when event != null => 'Bus departed at $event',
      JourneyState.absent => 'Marked absent',
      _ => null,
    };

    return [if (where.isNotEmpty) where, if (when != null) when]
        .join(' · ')
        .ifEmpty('No schedule for this leg');
  }
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
