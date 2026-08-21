part of 'pickup_persons_bloc.dart';

final class PickupPersonsState extends Equatable {
  const PickupPersonsState({
    this.children = const <ChildOption>[],
    this.selectedChild,
    this.people = const <PickupPerson>[],
    this.isLoadingList = false,
    this.listFailure,
    this.showAddForm = false,
    this.fullName = '',
    this.phone = '',
    this.relationshipNote = '',
    this.validFrom,
    this.validUntil,
    this.isSubmitting = false,
    this.submitFailure,
  });

  final List<ChildOption> children;
  final ChildOption? selectedChild;

  final List<PickupPerson> people;
  final bool isLoadingList;
  final Failure<void>? listFailure;

  final bool showAddForm;
  final String fullName;
  final String phone;
  final String relationshipNote;

  /// Mandatory and always populated with a default, never left blank (BR-GRD-005) — see
  /// `_defaultValidityWindow`.
  final DateTime? validFrom;
  final DateTime? validUntil;

  final bool isSubmitting;
  final Failure<void>? submitFailure;

  bool get isSubmittable =>
      selectedChild != null &&
      fullName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      validFrom != null &&
      validUntil != null &&
      !validUntil!.isBefore(validFrom!) &&
      !isSubmitting;

  PickupPersonsState copyWith({
    List<ChildOption>? children,
    ChildOption? selectedChild,
    List<PickupPerson>? people,
    bool? isLoadingList,
    Failure<void>? listFailure,
    bool clearListFailure = false,
    bool? showAddForm,
    String? fullName,
    String? phone,
    String? relationshipNote,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isSubmitting,
    Failure<void>? submitFailure,
    bool clearSubmitFailure = false,
  }) {
    return PickupPersonsState(
      children: children ?? this.children,
      selectedChild: selectedChild ?? this.selectedChild,
      people: people ?? this.people,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      listFailure: clearListFailure ? null : (listFailure ?? this.listFailure),
      showAddForm: showAddForm ?? this.showAddForm,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      relationshipNote: relationshipNote ?? this.relationshipNote,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitFailure: clearSubmitFailure ? null : (submitFailure ?? this.submitFailure),
    );
  }

  @override
  List<Object?> get props => [
        children,
        selectedChild,
        people,
        isLoadingList,
        listFailure?.code,
        showAddForm,
        fullName,
        phone,
        relationshipNote,
        validFrom,
        validUntil,
        isSubmitting,
        submitFailure?.code,
      ];
}
