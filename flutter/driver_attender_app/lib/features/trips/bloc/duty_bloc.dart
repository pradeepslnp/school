import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/time/clock.dart';
import '../domain/trip_models.dart';
import '../repository/trip_repository.dart';
import 'duty_event.dart';
import 'duty_state.dart';

/// The crew's day: which runs they are on, and starting and ending them (TRP-002/004).
///
/// Depends on a repository and a clock only — no HTTP, no fake server in its tests.
///
/// The clock is injected rather than `DateTime.now()` called directly because the start request
/// carries the handset's own time (BR-TRIP-008), and a test that could not fix it would be
/// asserting against whatever second it happened to run in.
class DutyBloc extends Bloc<DutyEvent, DutyState> {
  DutyBloc({required TripRepository repository, required Clock clock})
      : _repository = repository,
        _clock = clock,
        super(const DutyState()) {
    on<DutyRequested>(_onRequested);
    on<TripStartRequested>(_onStartRequested);
    on<TripEndRequested>(_onEndRequested);
  }

  final TripRepository _repository;
  final Clock _clock;

  Future<void> _onRequested(DutyRequested event, Emitter<DutyState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.myTrips();

    switch (result) {
      case Success<List<CrewTrip>>(:final value):
        emit(state.copyWith(
          isLoading: false,
          clearError: true,
          trips: value,
          loadedAt: _clock.nowUtc(),
        ));
      case Failure(:final code, :final messageKey):
        // loadedAt is deliberately not set: a failed refresh leaves the screen in "we could not
        // ask" rather than moving it to "you have no runs", which reads as good news.
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onStartRequested(
      TripStartRequested event, Emitter<DutyState> emit) async {
    emit(state.copyWith(submittingTripId: event.tripId, clearError: true));

    final result = await _repository.startTrip(
      tripId: event.tripId,
      vehicleId: event.vehicleId,
      deviceStartedAt: _clock.nowUtc(),
    );

    _applyOutcome(result, emit);
  }

  Future<void> _onEndRequested(TripEndRequested event, Emitter<DutyState> emit) async {
    emit(state.copyWith(submittingTripId: event.tripId, clearError: true));

    final result = await _repository.endTrip(tripId: event.tripId);

    _applyOutcome(result, emit);
  }

  /// Replaces the changed run in place rather than refetching the list: a reload costs a round
  /// trip on a handset that may be on one bar of signal, and moves the row under the driver's
  /// thumb.
  void _applyOutcome(Result<CrewTrip> result, Emitter<DutyState> emit) {
    switch (result) {
      case Success<CrewTrip>(:final value):
        emit(state.copyWith(
          clearSubmitting: true,
          clearError: true,
          trips: [
            for (final trip in state.trips)
              if (trip.id == value.id) value else trip,
          ],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(
          clearSubmitting: true,
          error: code,
          errorMessageKey: messageKey,
        ));
    }
  }
}
