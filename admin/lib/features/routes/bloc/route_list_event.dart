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
    this.defaultVehicleId,
  });

  final String schoolId;
  final String code;
  final String name;
  final String? defaultVehicleId;

  @override
  List<Object?> get props => [schoolId, code, name, defaultVehicleId];
}
