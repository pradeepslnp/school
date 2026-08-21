import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/child_detail_repository.dart';
import '../repository/models/child_detail.dart';

part 'child_detail_event.dart';
part 'child_detail_state.dart';

/// P-03 decisions. Depends on [ChildDetailRepository], never on the data provider
/// (ENGINEERING_PRINCIPLES.md §4).
class ChildDetailBloc extends Bloc<ChildDetailEvent, ChildDetailState> {
  ChildDetailBloc({required this.repository, required String studentId})
      : super(ChildDetailState(studentId: studentId)) {
    on<ChildDetailStarted>(_onStarted);
    on<ChildDetailRefreshed>(_onRefreshed);
  }

  final ChildDetailRepository repository;

  Future<void> _onStarted(
    ChildDetailStarted event,
    Emitter<ChildDetailState> emit,
  ) =>
      _load(emit);

  Future<void> _onRefreshed(
    ChildDetailRefreshed event,
    Emitter<ChildDetailState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<ChildDetailState> emit) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));

    final result = await repository.fetchDetail(studentId: state.studentId);

    switch (result) {
      case Success<ChildDetail>(:final value):
        emit(state.copyWith(isLoading: false, detail: value));
      case Failure<ChildDetail>(:final code, :final messageKey):
        emit(
          state.copyWith(
            isLoading: false,
            failure: Failure<void>(code, messageKey: messageKey),
          ),
        );
    }
  }
}
