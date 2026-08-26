import 'package:equatable/equatable.dart';

/// One stop on a route (RTE-001) — a boarding point with a location and a geofence, as returned
/// by `GET /routes/{id}/stops` and written back by `PUT /routes/{id}/stops`.
///
/// [id] is null for a stop the operator has added in the editor but not yet saved: stops are
/// written as a full ordered replacement (`PUT`), so a new one has no server id until the save
/// round-trips.
///
/// Times are kept as plain `HH:mm` strings rather than a `TimeOfDay`: they are optional, edited
/// as text, and the wire type is a local time-of-day with no date — a string is the honest shape
/// for "07:40, every operating day" (MOD-07-routes.md), and the domain layer stays free of
/// Flutter's `TimeOfDay`.
class RouteStop extends Equatable {
  const RouteStop({
    required this.sequenceNo,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusM,
    this.id,
    this.scheduledPickupTime,
    this.scheduledDropTime,
    this.landmark,
  });

  final String? id;
  final int sequenceNo;
  final String name;
  final double latitude;
  final double longitude;
  final int geofenceRadiusM;
  final String? scheduledPickupTime;
  final String? scheduledDropTime;
  final String? landmark;

  RouteStop copyWith({int? sequenceNo}) {
    return RouteStop(
      id: id,
      sequenceNo: sequenceNo ?? this.sequenceNo,
      name: name,
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusM: geofenceRadiusM,
      scheduledPickupTime: scheduledPickupTime,
      scheduledDropTime: scheduledDropTime,
      landmark: landmark,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sequenceNo,
        name,
        latitude,
        longitude,
        geofenceRadiusM,
        scheduledPickupTime,
        scheduledDropTime,
        landmark,
      ];
}
