import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../widgets/journey_status_chip.dart';
import '../repository/models/journey_history_entry.dart';

/// One row within a day's group — a single morning or afternoon leg that already happened.
class JourneyHistoryEntryTile extends StatelessWidget {
  const JourneyHistoryEntryTile({super.key, required this.entry});

  final JourneyHistoryEntry entry;

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
              entry.direction == JourneyDirection.morning ? 'Morning' : 'Afternoon',
              style: context.texts.titleMedium,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: JourneyStatusChip(state: entry.state),
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
    final where = [
      if (entry.vehicleDisplayName != null) entry.vehicleDisplayName!,
      if (entry.stopName != null) entry.stopName!,
    ].join(' · ');
    final at = entry.eventAt?.timeOfDay;

    final parts = [
      if (where.isNotEmpty) where,
      if (at != null) 'at $at',
    ];
    if (parts.isEmpty) {
      return entry.state == JourneyState.absent ? 'Marked absent' : 'No record for this leg';
    }
    return parts.join(' · ');
  }
}
