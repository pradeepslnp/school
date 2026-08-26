import 'package:equatable/equatable.dart';

/// A student's assignment to a route's stop, in one direction (RTE-003) — as returned by
/// `POST /routes/{routeId}/students` and `GET /students/{id}/route-assignments`.
///
/// The route and stop are named, not just referenced by id, because the enrolment screen reads
/// "Route R3 · Green Park", not two opaque ids. A student holds at most one active PICKUP and one
/// active DROP (BR-ROUTE-004), and the two may be on different routes (BR-ROUTE-005).
class RouteAssignment extends Equatable {
  const RouteAssignment({
    required this.id,
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.stopId,
    required this.stopName,
    required this.studentId,
    required this.direction,
    this.validFrom,
  });

  final String id;
  final String routeId;
  final String routeCode;
  final String routeName;
  final String stopId;
  final String stopName;
  final String studentId;

  /// `PICKUP` or `DROP`.
  final String direction;
  final DateTime? validFrom;

  bool get isPickup => direction == 'PICKUP';
  bool get isDrop => direction == 'DROP';

  @override
  List<Object?> get props => [
        id,
        routeId,
        routeCode,
        routeName,
        stopId,
        stopName,
        studentId,
        direction,
        validFrom,
      ];
}
