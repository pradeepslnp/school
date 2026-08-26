import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/stop_models.dart';
import '../repository/stop_repository.dart';
import 'route_stops_event.dart';
import 'route_stops_state.dart';

/// Loads, edits, and saves a route's stops (A-31 interim, RTE-001).
///
/// Depends on a repository only, never a data provider — matching `RouteListBloc`, so this is
/// tested with no HTTP and no fake server.
///
/// The add and remove events change only the in-memory working list; nothing reaches the server
/// until [RouteStopsSaved], which writes the whole list at once (`PUT`). That mirrors the
/// endpoint's replace-all contract and lets the operator build several stops before committing.
class RouteStopsBloc extends Bloc<RouteStopsEvent, RouteStopsState> {
  RouteStopsBloc({required StopRepository repository})
      : _repository = repository,
        super(const RouteStopsState()) {
    on<RouteStopsRequested>(_onRequested);
    on<StopAppended>(_onAppended);
    on<StopRemoved>(_onRemoved);
    on<RouteStopsSaved>(_onSaved);
  }

  final StopRepository _repository;

  Future<void> _onRequested(
      RouteStopsRequested event, Emitter<RouteStopsState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listStops(routeId: event.routeId);

    switch (result) {
      case Success<List<RouteStop>>(:final value):
        emit(state.copyWith(
            isLoading: false, clearError: true, stops: value, isDirty: false));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  void _onAppended(StopAppended event, Emitter<RouteStopsState> emit) {
    final next = [...state.stops, event.stop];
    emit(state.copyWith(stops: next, isDirty: true, clearError: true));
  }

  void _onRemoved(StopRemoved event, Emitter<RouteStopsState> emit) {
    if (event.index < 0 || event.index >= state.stops.length) return;
    final next = [...state.stops]..removeAt(event.index);
    emit(state.copyWith(stops: next, isDirty: true, clearError: true));
  }

  Future<void> _onSaved(RouteStopsSaved event, Emitter<RouteStopsState> emit) async {
    if (state.stops.length < 2) {
      // BR-ROUTE-001, mirrored client-side so the operator gets the message without a round
      // trip. The server enforces it regardless.
      emit(state.copyWith(error: ErrorCode.validationValueOutOfRange));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await _repository.replaceStops(routeId: event.routeId, stops: state.stops);

    switch (result) {
      case Success<List<RouteStop>>(:final value):
        emit(state.copyWith(
            isSaving: false, clearError: true, stops: value, isDirty: false));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSaving: false, error: code, errorMessageKey: messageKey));
    }
  }
}
