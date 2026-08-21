part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const [];
}

/// The dashboard was opened.
///
/// Shows the loading state, because there is nothing on screen yet to keep.
final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// The parent pulled to refresh, or tapped the refresh action.
///
/// Distinct from [HomeStarted] so the reload can keep the current cards on screen while it
/// runs. Blanking a dashboard a parent is reading, to show a spinner for data they already
/// have, takes information away at the moment they asked for more.
final class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}
