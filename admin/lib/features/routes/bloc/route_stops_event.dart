import 'package:equatable/equatable.dart';

import '../domain/stop_models.dart';

/// What the operator did in a route's stops editor (RTE-001).
sealed class RouteStopsEvent extends Equatable {
  const RouteStopsEvent();

  @override
  List<Object?> get props => const [];
}

/// The editor was opened for a route — load its current stops.
final class RouteStopsRequested extends RouteStopsEvent {
  const RouteStopsRequested({required this.routeId});

  final String routeId;

  @override
  List<Object?> get props => [routeId];
}

/// The operator added a stop to the working list (not yet saved).
final class StopAppended extends RouteStopsEvent {
  const StopAppended({required this.stop});

  final RouteStop stop;

  @override
  List<Object?> get props => [stop];
}

/// The operator removed the stop at [index] from the working list (not yet saved).
final class StopRemoved extends RouteStopsEvent {
  const StopRemoved({required this.index});

  final int index;

  @override
  List<Object?> get props => [index];
}

/// The operator saved the working list — replaces the route's stops in one request.
final class RouteStopsSaved extends RouteStopsEvent {
  const RouteStopsSaved({required this.routeId});

  final String routeId;

  @override
  List<Object?> get props => [routeId];
}
