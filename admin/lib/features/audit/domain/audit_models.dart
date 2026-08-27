import 'package:equatable/equatable.dart';

/// One audit record as the trail reads it (AUD-002, screen A-54). Returned by
/// `GET /audit-records` and `GET /audit-records/overrides`.
///
/// An append-only record of a safety-relevant action: who did what, to which subject, when, and —
/// for an override — why. The console only ever reads these; there is no create or edit path,
/// because a record is written server-side in the same transaction as the change it describes
/// (BR-AUD-002).
class AuditRecord extends Equatable {
  const AuditRecord({
    required this.id,
    required this.actorType,
    required this.action,
    required this.subjectType,
    required this.source,
    required this.occurredAt,
    this.actorId,
    this.actorRole,
    this.subjectId,
    this.reason,
  });

  final String id;
  final String? actorId;
  final String actorType;
  final String? actorRole;
  final String action;
  final String subjectType;
  final String? subjectId;
  final String? reason;
  final String source;
  final DateTime occurredAt;

  bool get isOverride => reason != null && reason!.isNotEmpty;

  /// The action code turned into something readable — `STUDENT_ASSIGNED_TO_ROUTE` reads as
  /// "Student assigned to route". Purely presentational; the raw code stays the source of truth.
  String get actionLabel {
    final words = action.toLowerCase().replaceAll('_', ' ').trim();
    if (words.isEmpty) return action;
    return words[0].toUpperCase() + words.substring(1);
  }

  @override
  List<Object?> get props => [
        id,
        actorId,
        actorType,
        actorRole,
        action,
        subjectType,
        subjectId,
        reason,
        source,
        occurredAt,
      ];
}
