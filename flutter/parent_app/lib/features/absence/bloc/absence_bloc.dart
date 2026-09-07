import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/absence_repository.dart';
import '../repository/models/absence.dart';

part 'absence_event.dart';
part 'absence_state.dart';

/// P-06 decisions: what counts as a submittable declaration, what a refusal means, and when
/// the confirmation is shown. The form widgets emit events and render state; they decide
/// nothing (ENGINEERING_PRINCIPLES.md §8).
///
/// Depends on [AbsenceRepository], never on the data provider.
class AbsenceBloc extends Bloc<AbsenceEvent, AbsenceState> {
  AbsenceBloc({
    required this.repository,
    required List<ChildOption> children,
  }) : super(AbsenceState(
          children: children,
          selectedChild: children.isEmpty ? null : children.first,
        )) {
    on<AbsenceStarted>(_onStarted);
    on<AbsenceRefreshed>(_onStarted);
    on<AbsenceChildSelected>(_onChildSelected);
    on<AbsenceWhenChanged>(_onWhenChanged);
    on<AbsenceDateRangeChanged>(_onDateRangeChanged);
    on<AbsenceJourneyChanged>(_onJourneyChanged);
    on<AbsenceReasonChanged>(_onReasonChanged);
    on<AbsenceSubmitted>(_onSubmitted);
    on<AbsenceCancelRequested>(_onCancelRequested);
  }

  final AbsenceRepository repository;

  Future<void> _onStarted(AbsenceEvent event, Emitter<AbsenceState> emit) =>
      _loadUpcoming(emit);

  Future<void> _onChildSelected(
    AbsenceChildSelected event,
    Emitter<AbsenceState> emit,
  ) async {
    if (event.child == state.selectedChild) return;
    emit(state.copyWith(
      selectedChild: event.child,
      upcoming: const [],
      clearConfirmation: true,
      clearSubmitFailure: true,
    ));
    await _loadUpcoming(emit);
  }

  void _onWhenChanged(AbsenceWhenChanged event, Emitter<AbsenceState> emit) {
    emit(state.copyWith(when: event.when, clearConfirmation: true));
  }

  void _onDateRangeChanged(AbsenceDateRangeChanged event, Emitter<AbsenceState> emit) {
    emit(state.copyWith(
      rangeFrom: event.from,
      rangeTo: event.to,
      clearConfirmation: true,
    ));
  }

  void _onJourneyChanged(AbsenceJourneyChanged event, Emitter<AbsenceState> emit) {
    emit(state.copyWith(direction: event.direction, clearConfirmation: true));
  }

  void _onReasonChanged(AbsenceReasonChanged event, Emitter<AbsenceState> emit) {
    emit(state.copyWith(reason: event.reason, clearConfirmation: true));
  }

  Future<void> _onSubmitted(AbsenceSubmitted event, Emitter<AbsenceState> emit) async {
    final child = state.selectedChild;
    final range = state.resolvedRange;
    if (child == null || range == null || state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, clearSubmitFailure: true, clearConfirmation: true));

    final result = await repository.declareAbsence(
      studentId: child.studentId,
      fromDate: range.$1,
      toDate: range.$2,
      direction: state.direction,
      reason: state.reason,
    );

    switch (result) {
      case Success<Absence>(:final value):
        emit(
          state.copyWith(
            isSubmitting: false,
            reason: '',
            confirmation: _buildConfirmation(child, value),
            upcoming: [...state.upcoming, value]..sort(
                (a, b) => a.fromDate.compareTo(b.fromDate),
              ),
          ),
        );
      case Failure<Absence>(:final code, :final messageKey, :final businessRule):
        emit(
          state.copyWith(
            isSubmitting: false,
            submitFailure: Failure<void>(code, messageKey: messageKey, businessRule: businessRule),
          ),
        );
    }
  }

  Future<void> _onCancelRequested(
    AbsenceCancelRequested event,
    Emitter<AbsenceState> emit,
  ) async {
    final child = state.selectedChild;
    if (child == null) return;

    final result = await repository.cancelAbsence(
      studentId: child.studentId,
      absenceId: event.absenceId,
    );

    switch (result) {
      case Success<void>():
        emit(
          state.copyWith(
            upcoming: state.upcoming.where((a) => a.id != event.absenceId).toList(),
          ),
        );
      case Failure<void>(:final code, :final messageKey, :final businessRule):
        emit(
          state.copyWith(
            submitFailure: Failure<void>(code, messageKey: messageKey, businessRule: businessRule),
          ),
        );
    }
  }

  Future<void> _loadUpcoming(Emitter<AbsenceState> emit) async {
    final child = state.selectedChild;
    if (child == null) return;

    emit(state.copyWith(isLoadingList: true, clearListFailure: true));
    final result = await repository.fetchAbsences(studentId: child.studentId);

    switch (result) {
      case Success<List<Absence>>(:final value):
        emit(state.copyWith(isLoadingList: false, upcoming: value));
      case Failure<List<Absence>>(:final code, :final messageKey):
        emit(
          state.copyWith(
            isLoadingList: false,
            listFailure: Failure<void>(code, messageKey: messageKey),
          ),
        );
    }
  }

  /// Carries the facts of the declaration; [_ConfirmationBanner] renders them through
  /// `context.l10n` (ADR-0013) — this bloc has no [BuildContext] to do that itself.
  static AbsenceConfirmation _buildConfirmation(ChildOption child, Absence absence) {
    return AbsenceConfirmation(
      childName: child.displayName,
      direction: absence.direction,
      fromDate: absence.fromDate,
      toDate: absence.toDate,
    );
  }
}
