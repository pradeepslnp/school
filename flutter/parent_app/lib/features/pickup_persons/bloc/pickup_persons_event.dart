part of 'pickup_persons_bloc.dart';

sealed class PickupPersonsEvent extends Equatable {
  const PickupPersonsEvent();

  @override
  List<Object?> get props => const [];
}

final class PickupPersonsStarted extends PickupPersonsEvent {
  const PickupPersonsStarted();
}

final class PickupPersonsRefreshed extends PickupPersonsEvent {
  const PickupPersonsRefreshed();
}

final class PickupPersonsChildSelected extends PickupPersonsEvent {
  const PickupPersonsChildSelected(this.child);

  final ChildOption child;

  @override
  List<Object?> get props => [child];
}

/// Shows or hides the "Add pickup person" form.
final class PickupPersonsAddFormToggled extends PickupPersonsEvent {
  const PickupPersonsAddFormToggled(this.show);

  final bool show;

  @override
  List<Object?> get props => [show];
}

final class PickupPersonsFullNameChanged extends PickupPersonsEvent {
  const PickupPersonsFullNameChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

final class PickupPersonsPhoneChanged extends PickupPersonsEvent {
  const PickupPersonsPhoneChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

final class PickupPersonsRelationshipChanged extends PickupPersonsEvent {
  const PickupPersonsRelationshipChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

final class PickupPersonsValidityChanged extends PickupPersonsEvent {
  const PickupPersonsValidityChanged({required this.from, required this.until});

  final DateTime from;
  final DateTime until;

  @override
  List<Object?> get props => [from, until];
}

final class PickupPersonsSubmitted extends PickupPersonsEvent {
  const PickupPersonsSubmitted();
}

final class PickupPersonsRevokeRequested extends PickupPersonsEvent {
  const PickupPersonsRevokeRequested(this.pickupPersonId);

  final String pickupPersonId;

  @override
  List<Object?> get props => [pickupPersonId];
}
