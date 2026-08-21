import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/journey_history_repository.dart';
import '../repository/models/journey_history_entry.dart';

part 'journey_history_event.dart';
part 'journey_history_state.dart';

/// P-05 decisions, including which of the guardian's children the list is showing.
///
/// Depends on [JourneyHistoryRepository], never on the data provider
/// (ENGINEERING_PRINCIPLES.md §4).
class JourneyHistoryBloc extends Bloc<JourneyHistoryEvent, JourneyHistoryState> {
  JourneyHistoryBloc({
    required this.repository,
    required List<ChildOption> children,
  }) : super(JourneyHistoryState(
          children: children,
          selected: children.isEmpty ? null : children.first,
        )) {
    on<JourneyHistoryStarted>(_onStarted);
    on<JourneyHistoryRefreshed>(_onRefreshed);
    on<JourneyHistoryChildSelected>(_onChildSelected);
  }

  final JourneyHistoryRepository repository;

  Future<void> _onStarted(
    JourneyHistoryStarted event,
    Emitter<JourneyHistoryState> emit,
  ) =>
      _load(emit);

  Future<void> _onRefreshed(
    JourneyHistoryRefreshed event,
    Emitter<JourneyHistoryState> emit,
  ) =>
      _load(emit);

  Future<void> _onChildSelected(
    JourneyHistoryChildSelected event,
    Emitter<JourneyHistoryState> emit,
  ) async {
    if (event.child == state.selected) return;
    emit(state.copyWith(selected: event.child, entries: const [], clearFailure: true));
    await _load(emit);
  }

  Future<void> _load(Emitter<JourneyHistoryState> emit) async {
    final selected = state.selected;
    if (selected == null) return;

    emit(state.copyWith(isLoading: true, clearFailure: true));

    final result = await repository.fetchHistory(studentId: selected.studentId);

    switch (result) {
      case Success<List<JourneyHistoryEntry>>(:final value):
        emit(state.copyWith(isLoading: false, entries: value));
      case Failure<List<JourneyHistoryEntry>>(:final code, :final messageKey):
        emit(
          state.copyWith(
            isLoading: false,
            failure: Failure<void>(code, messageKey: messageKey),
          ),
        );
    }
  }
}
