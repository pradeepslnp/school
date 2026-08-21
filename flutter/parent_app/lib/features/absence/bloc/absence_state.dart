part of 'absence_bloc.dart';

final class AbsenceState extends Equatable {
  const AbsenceState({
    this.children = const <ChildOption>[],
    this.selectedChild,
    this.when = AbsenceWhen.today,
    this.rangeFrom,
    this.rangeTo,
    this.direction = AbsenceDirection.both,
    this.reason = '',
    this.upcoming = const <Absence>[],
    this.isLoadingList = false,
    this.listFailure,
    this.isSubmitting = false,
    this.submitFailure,
    this.confirmation,
  });

  final List<ChildOption> children;
  final ChildOption? selectedChild;

  final AbsenceWhen when;

  /// Set only when [when] is [AbsenceWhen.dateRange].
  final DateTime? rangeFrom;
  final DateTime? rangeTo;

  final AbsenceDirection direction;
  final String reason;

  final List<Absence> upcoming;
  final bool isLoadingList;
  final Failure<void>? listFailure;

  final bool isSubmitting;
  final Failure<void>? submitFailure;

  /// Plain-language statement of effect, shown after a successful declaration —
  /// *"Aarav will not be expected on Bus 12 tomorrow morning."* (docs/05-ui/PARENT_APP.md).
  final String? confirmation;

  /// Today, tomorrow, or the picked range, resolved to concrete calendar dates. Null when a
  /// date range was chosen but not yet fully picked.
  (DateTime, DateTime)? get resolvedRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (when) {
      AbsenceWhen.today => (today, today),
      AbsenceWhen.tomorrow => (
          today.add(const Duration(days: 1)),
          today.add(const Duration(days: 1)),
        ),
      AbsenceWhen.dateRange => (rangeFrom == null || rangeTo == null)
          ? null
          : rangeTo!.isBefore(rangeFrom!)
              ? null
              : (rangeFrom!, rangeTo!),
    };
  }

  bool get isSubmittable =>
      selectedChild != null && resolvedRange != null && !isSubmitting;

  AbsenceState copyWith({
    List<ChildOption>? children,
    ChildOption? selectedChild,
    AbsenceWhen? when,
    DateTime? rangeFrom,
    DateTime? rangeTo,
    AbsenceDirection? direction,
    String? reason,
    List<Absence>? upcoming,
    bool? isLoadingList,
    Failure<void>? listFailure,
    bool clearListFailure = false,
    bool? isSubmitting,
    Failure<void>? submitFailure,
    bool clearSubmitFailure = false,
    String? confirmation,
    bool clearConfirmation = false,
  }) {
    return AbsenceState(
      children: children ?? this.children,
      selectedChild: selectedChild ?? this.selectedChild,
      when: when ?? this.when,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
      direction: direction ?? this.direction,
      reason: reason ?? this.reason,
      upcoming: upcoming ?? this.upcoming,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      listFailure: clearListFailure ? null : (listFailure ?? this.listFailure),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitFailure: clearSubmitFailure ? null : (submitFailure ?? this.submitFailure),
      confirmation: clearConfirmation ? null : (confirmation ?? this.confirmation),
    );
  }

  @override
  List<Object?> get props => [
        children,
        selectedChild,
        when,
        rangeFrom,
        rangeTo,
        direction,
        reason,
        upcoming,
        isLoadingList,
        listFailure?.code,
        isSubmitting,
        submitFailure?.code,
        confirmation,
      ];
}
