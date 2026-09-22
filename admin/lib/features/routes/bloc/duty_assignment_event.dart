import 'package:equatable/equatable.dart';

/// What the operator did in the crew-assignment dialog for one route (STF-004).
sealed class DutyAssignmentEvent extends Equatable {
  const DutyAssignmentEvent();

  @override
  List<Object?> get props => const [];
}

/// The dialog was opened for a route, or the operator asked to refresh its crew.
final class DutyAssignmentListRequested extends DutyAssignmentEvent {
  const DutyAssignmentListRequested({required this.routeId});

  final String routeId;

  @override
  List<Object?> get props => [routeId];
}

/// The operator assigned a driver or attendant to this route's standing roster.
final class DutyAssigned extends DutyAssignmentEvent {
  const DutyAssigned({
    required this.routeId,
    required this.staffId,
    required this.role,
    this.direction,
  });

  final String routeId;
  final String staffId;
  final String role;
  final String? direction;

  @override
  List<Object?> get props => [routeId, staffId, role, direction];
}

/// The operator put a different person on an existing duty — the regular crew member left, or is
/// away long enough that the standing roster should change (STF-004).
final class DutyReplaced extends DutyAssignmentEvent {
  const DutyReplaced({
    required this.routeId,
    required this.assignmentId,
    required this.staffId,
    required this.reason,
  });

  /// Kept so the list can be re-read after the change, which is what brings the new name back.
  final String routeId;
  final String assignmentId;
  final String staffId;
  final String reason;

  @override
  List<Object?> get props => [routeId, assignmentId, staffId, reason];
}

/// The operator took a crew member off this route's standing roster, leaving the slot empty.
final class DutyRemoved extends DutyAssignmentEvent {
  const DutyRemoved({required this.routeId, required this.assignmentId});

  final String routeId;
  final String assignmentId;

  @override
  List<Object?> get props => [routeId, assignmentId];
}
