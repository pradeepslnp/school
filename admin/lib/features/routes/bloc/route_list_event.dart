import 'package:equatable/equatable.dart';

/// What the operator did on the Routes screen (A-30).
sealed class RouteListEvent extends Equatable {
  const RouteListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown, or the operator asked to refresh, for one school's routes.
final class RouteListRequested extends RouteListEvent {
  const RouteListRequested({required this.schoolId});

  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}

/// The operator created a new route (RTE-001). Stops are added separately — see
/// `CreateRouteForm`'s own documentation on why this console does not collect them yet.
final class RouteCreated extends RouteListEvent {
  const RouteCreated({
    required this.schoolId,
    required this.code,
    required this.name,
    required this.operatingDays,
    this.defaultVehicleId,
  });

  final String schoolId;
  final String code;
  final String name;

  /// Comma-separated day codes (BR-TRIP-011). Required rather than optional: the form always
  /// has a value for it, and a route created with no days would never generate a trip.
  final String operatingDays;

  final String? defaultVehicleId;

  @override
  List<Object?> get props => [schoolId, code, name, operatingDays, defaultVehicleId];
}

/// The operator edited an existing route (RTE-001).
///
/// Every field but the id is nullable and null means *leave unchanged*, matching the `PATCH`
/// the server exposes: a screen that resent everything would overwrite a colleague's concurrent
/// rename with a value it never meant to change.
final class RouteEdited extends RouteListEvent {
  const RouteEdited({
    required this.schoolId,
    required this.routeId,
    this.name,
    this.defaultVehicleId,
    this.operatingDays,
  });

  /// Kept so the bloc can reload the list afterwards without the screen telling it again.
  final String schoolId;

  final String routeId;
  final String? name;
  final String? defaultVehicleId;
  final String? operatingDays;

  @override
  List<Object?> get props => [schoolId, routeId, name, defaultVehicleId, operatingDays];
}
