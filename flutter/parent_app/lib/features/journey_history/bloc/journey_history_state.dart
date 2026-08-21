part of 'journey_history_bloc.dart';

final class JourneyHistoryState extends Equatable {
  const JourneyHistoryState({
    this.children = const <ChildOption>[],
    this.selected,
    this.entries = const <JourneyHistoryEntry>[],
    this.isLoading = false,
    this.failure,
  });

  final List<ChildOption> children;
  final ChildOption? selected;
  final List<JourneyHistoryEntry> entries;
  final bool isLoading;
  final Failure<void>? failure;

  bool get showsFailureInsteadOfContent => failure != null && entries.isEmpty;

  JourneyHistoryState copyWith({
    List<ChildOption>? children,
    ChildOption? selected,
    List<JourneyHistoryEntry>? entries,
    bool? isLoading,
    Failure<void>? failure,
    bool clearFailure = false,
  }) {
    return JourneyHistoryState(
      children: children ?? this.children,
      selected: selected ?? this.selected,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [children, selected, entries, isLoading, failure?.code];
}
