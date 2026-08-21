part of 'live_trip_bloc.dart';

final class LiveTripState extends Equatable {
  const LiveTripState({
    this.trip,
    this.isLoading = false,
    this.failure,
    this.hasLoadedOnce = false,
  });

  final LiveTrip? trip;
  final bool isLoading;
  final Failure<void>? failure;
  final bool hasLoadedOnce;

  /// Whether the failure means tracking is unavailable because no trip is active
  /// (BR-TRACK-001) — the screen explains this rather than showing an empty map
  /// (docs/05-ui/PARENT_APP.md).
  bool get isOutsideTrip => failure?.code == ErrorCode.trackingNotAvailableOutsideTrip;

  bool get showsFailureInsteadOfContent => failure != null && trip == null;

  LiveTripState copyWith({
    LiveTrip? trip,
    bool? isLoading,
    Failure<void>? failure,
    bool clearFailure = false,
    bool? hasLoadedOnce,
  }) {
    return LiveTripState(
      trip: trip ?? this.trip,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  List<Object?> get props => [trip, isLoading, failure?.code, hasLoadedOnce];
}
