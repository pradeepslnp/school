part of 'journey_history_bloc.dart';

sealed class JourneyHistoryEvent extends Equatable {
  const JourneyHistoryEvent();

  @override
  List<Object?> get props => const [];
}

final class JourneyHistoryStarted extends JourneyHistoryEvent {
  const JourneyHistoryStarted();
}

final class JourneyHistoryRefreshed extends JourneyHistoryEvent {
  const JourneyHistoryRefreshed();
}

/// The parent switched which child's history is shown.
final class JourneyHistoryChildSelected extends JourneyHistoryEvent {
  const JourneyHistoryChildSelected(this.child);

  final ChildOption child;

  @override
  List<Object?> get props => [child];
}
