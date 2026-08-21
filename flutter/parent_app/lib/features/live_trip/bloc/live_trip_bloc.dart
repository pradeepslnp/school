import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/live_trip_repository.dart';
import '../repository/models/live_trip.dart';

part 'live_trip_event.dart';
part 'live_trip_state.dart';

/// P-04 decisions. Depends on [LiveTripRepository], never on the data provider
/// (ENGINEERING_PRINCIPLES.md §4).
///
/// Polls on a fixed interval while the screen is open, mirroring the WebSocket
/// `/topic/trip/{tripId}/position` push the real backend documents
/// (docs/04-api/TRACKING_NOTIFICATION_API.md) closely enough for this build of work, which
/// is scoped to the client only. Swapping the poll for a socket subscription later changes
/// this class, not the repository or the screen.
class LiveTripBloc extends Bloc<LiveTripEvent, LiveTripState> {
  LiveTripBloc({
    required this.repository,
    required String tripId,
    required String vehicleDisplayName,
    required String stopName,
    Duration pollInterval = const Duration(seconds: 5),
  })  : _tripId = tripId,
        _vehicleDisplayName = vehicleDisplayName,
        _stopName = stopName,
        super(const LiveTripState()) {
    on<LiveTripStarted>(_onStarted);
    on<LiveTripRefreshed>(_onRefreshed);
    _pollTimer = Timer.periodic(pollInterval, (_) => add(const LiveTripRefreshed()));
  }

  final LiveTripRepository repository;
  final String _tripId;
  final String _vehicleDisplayName;
  final String _stopName;
  late final Timer _pollTimer;

  Future<void> _onStarted(LiveTripStarted event, Emitter<LiveTripState> emit) =>
      _load(emit, showsSpinner: true);

  Future<void> _onRefreshed(LiveTripRefreshed event, Emitter<LiveTripState> emit) =>
      _load(emit, showsSpinner: false);

  Future<void> _load(Emitter<LiveTripState> emit, {required bool showsSpinner}) async {
    if (showsSpinner) emit(state.copyWith(isLoading: true, clearFailure: true));

    final result = await repository.fetchLiveTrip(
      tripId: _tripId,
      vehicleDisplayName: _vehicleDisplayName,
      stopName: _stopName,
    );

    switch (result) {
      case Success<LiveTrip>(:final value):
        emit(LiveTripState(trip: value, hasLoadedOnce: true));
      case Failure<LiveTrip>(:final code, :final messageKey, :final businessRule):
        emit(
          state.copyWith(
            isLoading: false,
            failure: Failure<void>(code, messageKey: messageKey, businessRule: businessRule),
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _pollTimer.cancel();
    return super.close();
  }
}
