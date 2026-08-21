import 'package:equatable/equatable.dart';

/// A route as returned by `POST /routes` or `GET /routes` (RTE-001).
class CreatedRoute extends Equatable {
  const CreatedRoute({
    required this.id,
    required this.schoolId,
    required this.code,
    required this.name,
    required this.active,
    this.defaultVehicleId,
  });

  final String id;
  final String schoolId;
  final String code;
  final String name;
  final String? defaultVehicleId;
  final bool active;

  bool get hasVehicle => defaultVehicleId != null;

  @override
  List<Object?> get props => [id, schoolId, code, name, defaultVehicleId, active];
}
