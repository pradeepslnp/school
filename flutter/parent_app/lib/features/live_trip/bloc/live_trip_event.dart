part of 'live_trip_bloc.dart';

sealed class LiveTripEvent extends Equatable {
  const LiveTripEvent();

  @override
  List<Object?> get props => const [];
}

/// The map screen was opened.
final class LiveTripStarted extends LiveTripEvent {
  const LiveTripStarted();
}

/// A poll tick, or the parent pulled to refresh. Distinct from [LiveTripStarted] so a
/// background poll never re-shows the spinner over a map the parent is already reading.
final class LiveTripRefreshed extends LiveTripEvent {
  const LiveTripRefreshed();
}
