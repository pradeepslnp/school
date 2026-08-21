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
