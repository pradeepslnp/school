part of 'child_detail_bloc.dart';

sealed class ChildDetailEvent extends Equatable {
  const ChildDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was opened for a given child.
final class ChildDetailStarted extends ChildDetailEvent {
  const ChildDetailStarted();
}

/// The parent pulled to refresh.
final class ChildDetailRefreshed extends ChildDetailEvent {
  const ChildDetailRefreshed();
}
