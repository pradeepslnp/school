import 'package:equatable/equatable.dart';

/// A person barred from collecting — or seeing — a child, overriding every guardian right
/// (BR-GRD-008 🔴, screen A-14). Contract: `STUDENTS_GUARDIANS_API.md` § Custody Restrictions.
///
/// Only the console ever holds one of these. There is no parent-app model of it and there must
/// never be — a restriction is invisible to the restricted person and to every guardian.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class CustodyRestriction extends Equatable {
  const CustodyRestriction({
    required this.id,
    required this.studentId,
    required this.restrictionType,
    required this.reason,
    required this.effectiveFrom,
    required this.active,
    this.restrictedGuardianId,
    this.restrictedPersonName,
    this.effectiveUntil,
  });

  final String id;
  final String studentId;
  final String? restrictedGuardianId;
  final String? restrictedPersonName;

  /// `NO_HANDOVER` · `NO_VISIBILITY` · `FULL`.
  final String restrictionType;
  final String reason;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;

  /// False once lifted. The list keeps lifted restrictions so the history stays visible.
  final bool active;

  @override
  List<Object?> get props => [
        id,
        studentId,
        restrictedGuardianId,
        restrictedPersonName,
        restrictionType,
        reason,
        effectiveFrom,
        effectiveUntil,
        active,
      ];
}

/// The subject of a new restriction — the form collects exactly one.
enum CustodyRestrictionType {
  noHandover('NO_HANDOVER'),
  noVisibility('NO_VISIBILITY'),
  full('FULL');

  const CustodyRestrictionType(this.wire);

  final String wire;
}
