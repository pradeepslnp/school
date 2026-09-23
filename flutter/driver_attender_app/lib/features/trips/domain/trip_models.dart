import 'package:equatable/equatable.dart';

/// Which leg of the school day a run is (BR-TRIP-001).
enum TripDirection {
  pickup,
  drop,
  /// A direction this build does not know. Shown as-is, never guessed at.
  unknown;

  static TripDirection fromWire(String? wire) => switch (wire) {
        'PICKUP' => pickup,
        'DROP' => drop,
        _ => unknown,
      };
}

/// The lifecycle of one run (BR-TRIP-002).
///
/// `unknown` exists because states ship additively within `v1` (API_STANDARDS.md): a handset in
/// the field will meet a status it was not built with, and must say so plainly rather than map it
/// onto the nearest familiar one — showing a cancelled run as "scheduled" is how a driver sets off
/// on a trip that was called off.
enum TripStatus {
  scheduled,
  inProgress,
  completed,
  closed,
  cancelled,
  unknown;

  static TripStatus fromWire(String? wire) => switch (wire) {
        'SCHEDULED' => scheduled,
        'IN_PROGRESS' => inProgress,
        'COMPLETED' => completed,
        'CLOSED' => closed,
        'CANCELLED' => cancelled,
        _ => unknown,
      };

  bool get canStart => this == scheduled;
  bool get canEnd => this == inProgress;
  bool get isOver => this == completed || this == closed || this == cancelled;
}

/// One of the crew's runs today, as `GET /trips/mine` returns it.
///
/// [expectedVehicleDisplayName] is the bus the *route* normally uses, not necessarily the one
/// running today: the vehicle becomes fact only when the trip starts (BR-TRIP-004). It is here
/// because a driver holds no `PERM-VEHICLE-VIEW` and the app has no other way to name the bus it
/// is about to ask them to confirm. Null when the route has no default vehicle — the screen then
/// says so instead of offering a start the server would refuse.
class CrewTrip extends Equatable {
  const CrewTrip({
    required this.id,
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.direction,
    required this.status,
    this.stopCount,
    this.scheduledStartTime,
    this.startedAt,
    this.endedAt,
    this.vehicleId,
    this.expectedVehicleId,
    this.expectedVehicleDisplayName,
    this.expectedVehicleRegistrationNo,
    this.cancelledReason,
  });

  final String id;
  final String routeId;
  final String routeCode;
  final String routeName;
  final TripDirection direction;
  final TripStatus status;
  final String? stopCount;

  /// Wall-clock time in the school's zone, e.g. `07:15`. Not an instant: a timetable is a
  /// wall-clock fact that survives daylight saving, where an instant would drift.
  final String? scheduledStartTime;

  final DateTime? startedAt;
  final DateTime? endedAt;

  /// The bus actually running this trip. Null until it starts.
  final String? vehicleId;

  final String? expectedVehicleId;
  final String? expectedVehicleDisplayName;
  final String? expectedVehicleRegistrationNo;
  final String? cancelledReason;

  /// Whether the crew can be offered a start: the run has not begun, and there is a bus to name.
  bool get isStartable => status.canStart && expectedVehicleId != null;

  /// The run is ready to go but the route has no bus on file — an office problem, not a driver's.
  bool get needsVehicleFromOffice => status.canStart && expectedVehicleId == null;

  @override
  List<Object?> get props => [id, status, vehicleId, startedAt, endedAt];
}
