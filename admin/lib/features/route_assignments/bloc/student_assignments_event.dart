import 'package:equatable/equatable.dart';

/// What the operator did on a student's pickup/drop panel (RTE-003).
sealed class StudentAssignmentsEvent extends Equatable {
  const StudentAssignmentsEvent();

  @override
  List<Object?> get props => const [];
}

/// The panel was opened for a student, or the operator asked to refresh it.
final class StudentAssignmentsRequested extends StudentAssignmentsEvent {
  const StudentAssignmentsRequested({required this.studentId});

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}

/// The operator assigned the student to a route's stop for one direction.
final class StudentAssignmentAdded extends StudentAssignmentsEvent {
  const StudentAssignmentAdded({
    required this.studentId,
    required this.routeId,
    required this.stopId,
    required this.direction,
  });

  final String studentId;
  final String routeId;
  final String stopId;
  final String direction;

  @override
  List<Object?> get props => [studentId, routeId, stopId, direction];
}

/// The operator removed one of the student's assignments.
final class StudentAssignmentRemoved extends StudentAssignmentsEvent {
  const StudentAssignmentRemoved({required this.studentId, required this.assignmentId});

  final String studentId;
  final String assignmentId;

  @override
  List<Object?> get props => [studentId, assignmentId];
}
