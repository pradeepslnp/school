import 'package:equatable/equatable.dart';

/// What the crew did on the Today screen (TRP-002/004).
sealed class DutyEvent extends Equatable {
  const DutyEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened, or the crew pulled to refresh.
final class DutyRequested extends DutyEvent {
  const DutyRequested();
}

/// The crew confirmed the bus in front of them and started the run.
final class TripStartRequested extends DutyEvent {
  const TripStartRequested({required this.tripId, required this.vehicleId});

  final String tripId;
  final String vehicleId;

  @override
  List<Object?> get props => [tripId, vehicleId];
}

/// The crew finished driving.
final class TripEndRequested extends DutyEvent {
  const TripEndRequested({required this.tripId});

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}
