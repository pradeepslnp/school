import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/time/clock.dart';
import '../domain/manifest_models.dart';
import '../repository/trip_repository.dart';
import 'manifest_event.dart';
import 'manifest_state.dart';

/// One run's manifest, and recording what happens to the children on it (BRD-001..004).
///
/// **The row moves the instant the crew taps.** The boarding event is written to the outbound
/// queue, which is durable, and the state is updated from that — not from a server reply
/// (ADR-0008). An attendant with a queue of children at the door must see the tap land
/// immediately, and on a bus at the edge of coverage a server reply may be minutes away.
///
/// The row is marked `pendingSync` rather than silently shown as confirmed, so the screen can say
/// which records the server has not yet acknowledged. The sync banner above it reports the queue
/// as a whole.
class ManifestBloc extends Bloc<ManifestEvent, ManifestState> {
  ManifestBloc({
    required TripRepository repository,
    required Clock clock,
    required this.tripId,
  })  : _repository = repository,
        _clock = clock,
        super(const ManifestState()) {
    on<ManifestRequested>(_onRequested);
    on<BoardingRecorded>(_onBoardingRecorded);
  }

  final TripRepository _repository;
  final Clock _clock;
  final String tripId;

  Future<void> _onRequested(ManifestRequested event, Emitter<ManifestState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.manifest(tripId: tripId);

    switch (result) {
      case Success<List<ManifestChild>>(:final value):
        // Locally-recorded events are preserved across a refresh: the server may not have heard
        // about them yet, and a refresh that reverted a child to "not boarded" would invite the
        // crew to record the same boarding twice.
        emit(state.copyWith(
          isLoading: false,
          clearError: true,
          children: _mergePending(value),
          loadedAt: _clock.nowUtc(),
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  List<ManifestChild> _mergePending(List<ManifestChild> fromServer) {
    final pending = {
      for (final child in state.children)
        if (child.pendingSync) child.studentId: child,
    };
    return [
      for (final child in fromServer)
        if (pending.containsKey(child.studentId) &&
            child.status != pending[child.studentId]!.status)
          child.copyWith(status: pending[child.studentId]!.status, pendingSync: true)
        else
          child,
    ];
  }

  Future<void> _onBoardingRecorded(
      BoardingRecorded event, Emitter<ManifestState> emit) async {
    final child = state.children.where((c) => c.studentId == event.studentId).firstOrNull;
    if (child == null) return;

    await _repository.recordBoarding(
      tripId: tripId,
      studentId: event.studentId,
      stopId: child.expectedStopId,
      isBoarding: event.isBoarding,
      overrideReason: event.overrideReason,
    );

    emit(state.copyWith(
      children: [
        for (final c in state.children)
          if (c.studentId == event.studentId)
            c.copyWith(
              status: event.isBoarding
                  ? ManifestEntryStatus.boarded
                  : ManifestEntryStatus.alighted,
              pendingSync: true,
            )
          else
            c,
      ],
    ));
  }
}
