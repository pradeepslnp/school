part of 'absence_bloc.dart';

/// Which dates a declaration covers, before it is resolved to concrete calendar dates
/// (docs/05-ui/PARENT_APP.md P-06: "( ) Today ( ) Tomorrow ( ) Date range").
enum AbsenceWhen { today, tomorrow, dateRange }

sealed class AbsenceEvent extends Equatable {
  const AbsenceEvent();

  @override
  List<Object?> get props => const [];
}

final class AbsenceStarted extends AbsenceEvent {
  const AbsenceStarted();
}

final class AbsenceRefreshed extends AbsenceEvent {
  const AbsenceRefreshed();
}

final class AbsenceChildSelected extends AbsenceEvent {
  const AbsenceChildSelected(this.child);

  final ChildOption child;

  @override
  List<Object?> get props => [child];
}

final class AbsenceWhenChanged extends AbsenceEvent {
  const AbsenceWhenChanged(this.when);

  final AbsenceWhen when;

  @override
  List<Object?> get props => [when];
}

/// Only meaningful once [AbsenceWhenChanged] has selected [AbsenceWhen.dateRange].
final class AbsenceDateRangeChanged extends AbsenceEvent {
  const AbsenceDateRangeChanged({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

final class AbsenceJourneyChanged extends AbsenceEvent {
  const AbsenceJourneyChanged(this.direction);

  final AbsenceDirection direction;

  @override
  List<Object?> get props => [direction];
}

final class AbsenceReasonChanged extends AbsenceEvent {
  const AbsenceReasonChanged(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class AbsenceSubmitted extends AbsenceEvent {
  const AbsenceSubmitted();
}

final class AbsenceCancelRequested extends AbsenceEvent {
  const AbsenceCancelRequested(this.absenceId);

  final String absenceId;

  @override
  List<Object?> get props => [absenceId];
}
