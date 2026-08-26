import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/platform_health_models.dart';
import '../repository/platform_health_repository.dart';
import 'platform_health_event.dart';
import 'platform_health_state.dart';

/// Loads Platform health (A-62), `SUPER_ADMIN` only.
class PlatformHealthBloc extends Bloc<PlatformHealthEvent, PlatformHealthState> {
  PlatformHealthBloc({required PlatformHealthRepository repository})
      : _repository = repository,
        super(const PlatformHealthState()) {
    on<PlatformHealthRequested>(_onRequested);
  }

  final PlatformHealthRepository _repository;

  Future<void> _onRequested(
    PlatformHealthRequested event,
    Emitter<PlatformHealthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.getHealth();

    switch (result) {
      case Success<PlatformHealth>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, health: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }
}
