import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/route_models.dart';
import '../repository/route_repository.dart';
import 'route_list_event.dart';
import 'route_list_state.dart';

/// Creates and lists routes for one school (A-30, RTE-001).
///
/// Depends on a repository only, never a data provider — matching `VehicleListBloc`, so this
/// is tested with no HTTP and no fake server.
class RouteListBloc extends Bloc<RouteListEvent, RouteListState> {
  RouteListBloc({required RouteRepository repository})
      : _repository = repository,
        super(const RouteListState()) {
    on<RouteListRequested>(_onRequested);
    on<RouteCreated>(_onCreated);
  }

  final RouteRepository _repository;

  Future<void> _onRequested(RouteListRequested event, Emitter<RouteListState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.listRoutes(schoolId: event.schoolId);

    switch (result) {
      case Success<List<CreatedRoute>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, routes: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }

  Future<void> _onCreated(RouteCreated event, Emitter<RouteListState> emit) async {
    if (event.schoolId.trim().isEmpty ||
        event.code.trim().isEmpty ||
        event.name.trim().isEmpty) {
      emit(state.copyWith(error: ErrorCode.validationRequiredFieldMissing));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.createRoute(
      schoolId: event.schoolId,
      code: event.code,
      name: event.name,
      defaultVehicleId: event.defaultVehicleId,
    );

    switch (result) {
      case Success<CreatedRoute>(:final value):
        emit(state.copyWith(
          isSubmitting: false,
          clearError: true,
          routes: [value, ...state.routes],
        ));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isSubmitting: false, error: code, errorMessageKey: messageKey));
    }
  }
}
