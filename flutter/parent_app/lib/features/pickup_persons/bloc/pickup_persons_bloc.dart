import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/models/pickup_person.dart';
import '../repository/pickup_persons_repository.dart';

part 'pickup_persons_event.dart';
part 'pickup_persons_state.dart';

/// The short window PARENT_APP.md asks the form to default to, rather than a long or open
/// one (BR-GRD-005) — a guardian shortens or lengthens it deliberately, but never has to
/// remember to set it at all.
const _defaultValidityWindow = Duration(days: 7);

/// P-07 decisions: what counts as a submittable nomination, and what a refusal means. Form
/// widgets emit events and render state; they decide nothing (ENGINEERING_PRINCIPLES.md §8).
class PickupPersonsBloc extends Bloc<PickupPersonsEvent, PickupPersonsState> {
  PickupPersonsBloc({
    required this.repository,
    required List<ChildOption> children,
  }) : super(_initial(children)) {
    on<PickupPersonsStarted>(_onStarted);
    on<PickupPersonsRefreshed>(_onStarted);
    on<PickupPersonsChildSelected>(_onChildSelected);
    on<PickupPersonsAddFormToggled>(_onAddFormToggled);
    on<PickupPersonsFullNameChanged>(
      (e, emit) => emit(state.copyWith(fullName: e.value)),
    );
    on<PickupPersonsPhoneChanged>(
      (e, emit) => emit(state.copyWith(phone: e.value)),
    );
    on<PickupPersonsRelationshipChanged>(
      (e, emit) => emit(state.copyWith(relationshipNote: e.value)),
    );
    on<PickupPersonsValidityChanged>(
      (e, emit) => emit(state.copyWith(validFrom: e.from, validUntil: e.until)),
    );
    on<PickupPersonsSubmitted>(_onSubmitted);
    on<PickupPersonsRevokeRequested>(_onRevokeRequested);
  }

  final PickupPersonsRepository repository;

  static PickupPersonsState _initial(List<ChildOption> children) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return PickupPersonsState(
      children: children,
      selectedChild: children.isEmpty ? null : children.first,
      validFrom: today,
      validUntil: today.add(_defaultValidityWindow),
    );
  }

  Future<void> _onStarted(
    PickupPersonsEvent event,
    Emitter<PickupPersonsState> emit,
  ) =>
      _load(emit);

  Future<void> _onChildSelected(
    PickupPersonsChildSelected event,
    Emitter<PickupPersonsState> emit,
  ) async {
    if (event.child == state.selectedChild) return;
    emit(state.copyWith(selectedChild: event.child, people: const [], clearSubmitFailure: true));
    await _load(emit);
  }

  void _onAddFormToggled(
    PickupPersonsAddFormToggled event,
    Emitter<PickupPersonsState> emit,
  ) {
    emit(state.copyWith(showAddForm: event.show, clearSubmitFailure: true));
  }

  Future<void> _onSubmitted(
    PickupPersonsSubmitted event,
    Emitter<PickupPersonsState> emit,
  ) async {
    final child = state.selectedChild;
    if (child == null || !state.isSubmittable) return;

    emit(state.copyWith(isSubmitting: true, clearSubmitFailure: true));

    final result = await repository.addPickupPerson(
      studentId: child.studentId,
      fullName: state.fullName.trim(),
      phone: state.phone.trim(),
      relationshipNote: state.relationshipNote.trim().isEmpty ? null : state.relationshipNote.trim(),
      validFrom: state.validFrom!,
      validUntil: state.validUntil!,
    );

    switch (result) {
      case Success<PickupPerson>(:final value):
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        emit(
          state.copyWith(
            isSubmitting: false,
            showAddForm: false,
            fullName: '',
            phone: '',
            relationshipNote: '',
            validFrom: today,
            validUntil: today.add(_defaultValidityWindow),
            people: [...state.people, value]..sort(
                (a, b) => a.validUntil.compareTo(b.validUntil),
              ),
          ),
        );
      case Failure<PickupPerson>(:final code, :final messageKey, :final businessRule):
        emit(
          state.copyWith(
            isSubmitting: false,
            submitFailure: Failure<void>(code, messageKey: messageKey, businessRule: businessRule),
          ),
        );
    }
  }

  Future<void> _onRevokeRequested(
    PickupPersonsRevokeRequested event,
    Emitter<PickupPersonsState> emit,
  ) async {
    final child = state.selectedChild;
    if (child == null) return;

    final result = await repository.revokePickupPerson(
      studentId: child.studentId,
      pickupPersonId: event.pickupPersonId,
    );

    switch (result) {
      case Success<void>():
        emit(
          state.copyWith(
            people: state.people.where((p) => p.id != event.pickupPersonId).toList(),
          ),
        );
      case Failure<void>(:final code, :final messageKey):
        emit(state.copyWith(submitFailure: Failure<void>(code, messageKey: messageKey)));
    }
  }

  Future<void> _load(Emitter<PickupPersonsState> emit) async {
    final child = state.selectedChild;
    if (child == null) return;

    emit(state.copyWith(isLoadingList: true, clearListFailure: true));
    final result = await repository.fetchPickupPersons(studentId: child.studentId);

    switch (result) {
      case Success<List<PickupPerson>>(:final value):
        emit(state.copyWith(isLoadingList: false, people: value));
      case Failure<List<PickupPerson>>(:final code, :final messageKey):
        emit(
          state.copyWith(
            isLoadingList: false,
            listFailure: Failure<void>(code, messageKey: messageKey),
          ),
        );
    }
  }
}
