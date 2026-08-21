import 'package:flutter/foundation.dart';

/// Which leg an absence covers. `null` on the wire means both (BR-ABS-001) — modelled here
/// as an explicit [both] rather than a nullable field, so a screen never has to ask "does
/// null mean both, or unknown?".
enum AbsenceDirection { both, morningOnly, afternoonOnly }

/// A declared absence — P-06's "Aarav will not be expected on Bus 12 tomorrow morning."
@immutable
class Absence {
  const Absence({
    required this.id,
    required this.studentId,
    required this.fromDate,
    required this.toDate,
    required this.direction,
    this.reason,
  });

  final String id;
  final String studentId;

  /// Calendar dates, school-local — not instants (docs/04-api/API_STANDARDS.md: dates are
  /// `YYYY-MM-DD`).
  final DateTime fromDate;
  final DateTime toDate;
  final AbsenceDirection direction;

  /// Optional — requiring a parent to justify an absence is friction with no safety value
  /// (BR-ABS-001).
  final String? reason;
}
