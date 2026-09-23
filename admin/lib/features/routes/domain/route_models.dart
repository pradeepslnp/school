import 'package:equatable/equatable.dart';

/// A route as returned by `POST /routes` or `GET /routes` (RTE-001).
class CreatedRoute extends Equatable {
  const CreatedRoute({
    required this.id,
    required this.schoolId,
    required this.code,
    required this.name,
    required this.operatingDays,
    required this.active,
    this.defaultVehicleId,
  });

  final String id;
  final String schoolId;
  final String code;
  final String name;
  final String? defaultVehicleId;

  /// Which days this route runs, as the API stores it: comma-separated three-letter codes,
  /// e.g. `MON,TUE,WED,THU,FRI` (BR-TRIP-011).
  ///
  /// Kept as the server's own string rather than parsed into a set here. The console's job is
  /// to show it and hand back an edited version; the server owns what a valid value is, and a
  /// second opinion in Dart is a second thing to keep in step.
  final String operatingDays;

  final bool active;

  bool get hasVehicle => defaultVehicleId != null;

  /// The days, in order, for display. An unrecognised code is passed through rather than
  /// dropped — if the server ever sends one, showing it is how anyone finds out.
  List<String> get operatingDayCodes => operatingDays
      .split(',')
      .map((code) => code.trim())
      .where((code) => code.isNotEmpty)
      .toList(growable: false);

  @override
  List<Object?> get props => [
        id,
        schoolId,
        code,
        name,
        defaultVehicleId,
        operatingDays,
        active,
      ];
}
