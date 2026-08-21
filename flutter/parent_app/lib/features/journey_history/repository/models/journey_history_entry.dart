import 'package:flutter/foundation.dart';

import '../../../../core/domain.dart';

/// One past leg — a single morning or afternoon journey on a single day.
///
/// P-05's durable record: "a parent who missed what happened must be able to scroll back
/// and find it" (docs/05-ui/PARENT_APP.md, said of P-08 and equally true here).
@immutable
class JourneyHistoryEntry {
  const JourneyHistoryEntry({
    required this.serviceDate,
    required this.direction,
    required this.state,
    this.vehicleDisplayName,
    this.stopName,
    this.eventAt,
  });

  /// The school day this leg belongs to, in school-local terms — a calendar date, not an
  /// instant (docs/04-api/API_STANDARDS.md: dates are `YYYY-MM-DD`, distinct from
  /// timestamps).
  final DateTime serviceDate;

  final JourneyDirection direction;
  final JourneyState state;
  final String? vehicleDisplayName;
  final String? stopName;

  /// When the terminal event on this leg happened — boarding, arrival, or handover.
  final SchoolTime? eventAt;
}
