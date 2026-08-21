import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/handover_repository.dart';
import '../repository/models/handover_code.dart';

part 'handover_event.dart';
part 'handover_state.dart';

/// P-12 decisions: which child's code is showing, and when to ask for a fresh one. The
/// screen emits events and renders state; it decides nothing (ENGINEERING_PRINCIPLES.md §8).
///
/// Depends on [HandoverRepository], never on the data provider.
class HandoverBloc extends Bloc<HandoverEvent, HandoverState> {
  HandoverBloc({
    required this.repository,
    required List<ChildOption> children,
  }) : super(HandoverState(
          children: children,
          selected: children.isEmpty ? null : children.first,
        )) {
    on<HandoverStarted>(_onStarted);
    on<HandoverChildSelected>(_onChildSelected);
    on<HandoverCodeRequested>(_onCodeRequested);
  }

  final HandoverRepository repository;

  Future<void> _onStarted(HandoverEvent event, Emitter<HandoverState> emit) =>
      _requestCode(emit);

  Future<void> _onChildSelected(
    HandoverChildSelected event,
    Emitter<HandoverState> emit,
  ) async {
    if (event.child == state.selected) return;
    emit(state.copyWith(
      selected: event.child,
      clearCode: true,
      clearFailure: true,
    ));
    await _requestCode(emit);
  }

  Future<void> _onCodeRequested(
    HandoverCodeRequested event,
    Emitter<HandoverState> emit,
  ) =>
      _requestCode(emit);

  Future<void> _requestCode(Emitter<HandoverState> emit) async {
    final child = state.selected;
    if (child == null) return;

    emit(state.copyWith(isLoading: true, clearFailure: true));
    final result = await repository.requestCode(studentId: child.studentId);

    switch (result) {
      case Success<HandoverCode>(:final value):
        emit(state.copyWith(isLoading: false, code: value));
      case Failure<HandoverCode>(:final code, :final messageKey):
        emit(
          state.copyWith(
            isLoading: false,
            failure: Failure<void>(code, messageKey: messageKey),
          ),
        );
    }
  }
}
