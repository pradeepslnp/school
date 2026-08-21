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
  });

  final String id;
  final String staffId;
  final String routeId;
  final String role;

  /// Null means both directions (STF-004).
  final String? direction;
  final bool active;

  @override
  List<Object?> get props => [id, staffId, routeId, role, direction, active];
}
