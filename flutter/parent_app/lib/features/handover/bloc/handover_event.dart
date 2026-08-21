part of 'handover_bloc.dart';

sealed class HandoverEvent extends Equatable {
  const HandoverEvent();

  @override
  List<Object?> get props => const [];
}

/// Requests a code for the initially-selected child (the first, when there is more than
/// one — the same default every other multi-child form in this app uses).
final class HandoverStarted extends HandoverEvent {
  const HandoverStarted();
}

final class HandoverChildSelected extends HandoverEvent {
  const HandoverChildSelected(this.child);

  final ChildOption child;

  @override
  List<Object?> get props => [child];
}

/// Requests a fresh code for the currently-selected child — used both by the initial load
/// and by "generate a new code" once the shown one has expired.
final class HandoverCodeRequested extends HandoverEvent {
  const HandoverCodeRequested();
}
