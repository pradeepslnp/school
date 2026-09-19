import 'package:equatable/equatable.dart';

/// The bus and crew a student is assigned to, per direction — `GET /students/{id}/transport`
/// (STU-009, A-11).
///
/// **The plan, not the child's whereabouts.** It is the route the child is assigned to, that
/// route's default bus, and today's duty crew. A running trip may use a substitute bus or crew,
/// and only boarding records say where the child actually is — which is why the panel says
/// "assigned" and never "on".
class StudentTransport extends Equatable {
  const StudentTransport({required this.legs});

  /// Pickup first; empty when the student has no route assignment.
  final List<TransportLeg> legs;

  @override
  List<Object?> get props => [legs];
}

/// One direction (`PICKUP` or `DROP`) of a student's assigned transport.
class TransportLeg extends Equatable {
  const TransportLeg({
    required this.direction,
    required this.routeCode,
    required this.routeName,
    required this.stopName,
    required this.crew,
    this.vehicle,
  });

  final String direction;
  final String routeCode;
  final String routeName;
  final String stopName;

  /// Null when the route has no default bus set.
  final TransportVehicle? vehicle;

  /// Driver(s) first, then attendant(s); empty when nobody is on duty for this route today.
  final List<TransportCrewMember> crew;

  List<TransportCrewMember> get drivers =>
      crew.where((member) => member.role == 'DRIVER').toList(growable: false);

  List<TransportCrewMember> get attendants =>
      crew.where((member) => member.role == 'ATTENDANT').toList(growable: false);

  @override
  List<Object?> get props => [direction, routeCode, routeName, stopName, vehicle, crew];
}

class TransportVehicle extends Equatable {
  const TransportVehicle({
    required this.registrationNo,
    required this.displayName,
    required this.status,
  });

  final String registrationNo;
  final String displayName;

  /// `ACTIVE`, `MAINTENANCE`, or `RETIRED`. Anything but `ACTIVE` is shown as a warning: the
  /// route still points at a bus that is not running.
  final String status;

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [registrationNo, displayName, status];
}

class TransportCrewMember extends Equatable {
  const TransportCrewMember({required this.role, required this.firstName, required this.lastName});

  final String role;
  final String firstName;
  final String lastName;

  String get displayName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [role, firstName, lastName];
}
