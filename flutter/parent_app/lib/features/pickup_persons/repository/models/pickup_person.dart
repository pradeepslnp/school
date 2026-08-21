import 'package:flutter/foundation.dart';

/// Someone nominated to collect a child, other than a guardian — P-07.
///
/// A validity window is mandatory (BR-GRD-005): nominations always expire, so a permanent
/// authorisation made once and forgotten can never exist in this model.
@immutable
class PickupPerson {
  const PickupPerson({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.phone,
    required this.validFrom,
    required this.validUntil,
    this.relationshipNote,
  });

  final String id;
  final String studentId;
  final String fullName;
  final String phone;

  /// Descriptive only — "Uncle", "Family friend" — never a right in itself
  /// (docs/04-api/STUDENTS_GUARDIANS_API.md: rights are explicit, never inferred).
  final String? relationshipNote;

  final DateTime validFrom;
  final DateTime validUntil;

  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isNotYetValid => DateTime.now().isBefore(validFrom);
}
