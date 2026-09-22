import 'package:equatable/equatable.dart';

/// A duty assignment as returned by `POST` or `GET .../duty-assignments` (STF-004).
class CreatedDutyAssignment extends Equatable {
  const CreatedDutyAssignment({
    required this.id,
    required this.staffId,
    required this.routeId,
    required this.role,
    required this.active,
    this.direction,
    this.staffFirstName,
    this.staffLastName,
  });

  final String id;
  final String staffId;

  /// Who holds the duty. Null on the response to an assignment just created — the list is
  /// re-read afterwards, which is where the names come from.
  final String? staffFirstName;
  final String? staffLastName;

  /// The crew member's name, or empty when their staff record is gone (the row still shows, so
  /// an unfilled crew slot is visible).
  String get displayName => '${staffFirstName ?? ''} ${staffLastName ?? ''}'.trim();
  final String routeId;
  final String role;

  /// Null means both directions (STF-004).
  final String? direction;
  final bool active;

  @override
  List<Object?> get props =>
      [id, staffId, routeId, role, direction, active, staffFirstName, staffLastName];
}
