import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/home_repository.dart';
import '../repository/models/child_status.dart';
import '../repository/models/children_snapshot.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Dashboard decisions.
///
/// Owns what a failure means, what survives it, and when the screen may show nothing. The
/// UI reads state and emits events — it decides nothing
/// (ENGINEERING_PRINCIPLES.md §8).
///
/// Depends on [HomeRepository], never on the data provider, so it is tested with a fake
/// repository and no HTTP.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this.repository}) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshed>(_onRefreshed);
  }

  final HomeRepository repository;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) =>
      _load(emit);

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) =>
      _load(emit);

  Future<void> _load(Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));

    final result = await repository.fetchChildren();

    switch (result) {
      case Success<ChildrenSnapshot>(:final value):
        emit(
          HomeState(
            children: value.children,
            observedAt: value.observedAt,
            hasLoadedOnce: true,
          ),
        );
      case Failure<ChildrenSnapshot>(
          :final code,
          :final messageKey,
          :final businessRule,
        ):
        emit(
          // The children already on screen are kept deliberately. This app is a read
          // surface (ADR-0008): a failed refresh means the parent's *view* went stale, and
          // last-known state with an honest freshness label beats a blank screen
          // (docs/05-ui/PARENT_APP.md). The banner is what stops it reading as current.
          state.copyWith(
            isLoading: false,
            failure: Failure<void>(
              code,
              messageKey: messageKey,
              businessRule: businessRule,
            ),
          ),
        );
    }
  }
}
