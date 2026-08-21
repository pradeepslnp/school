part of 'home_bloc.dart';

/// Everything the dashboard needs to render, and nothing it has to work out.
///
/// The screen reads these fields directly. A widget that computes "am I offline" from a
/// failure code is a widget making a decision (ENGINEERING_PRINCIPLES.md §8).
final class HomeState extends Equatable {
  const HomeState({
    this.children = const <ChildStatus>[],
    this.isLoading = false,
    this.failure,
    this.observedAt,
    this.hasLoadedOnce = false,
  });

  final List<ChildStatus> children;

  /// A load is in flight. True for both the first load and a refresh; the screen tells them
  /// apart by whether [children] is empty.
  final bool isLoading;

  /// The last load's failure, or null.
  final Failure<void>? failure;

  /// When the shown data was produced, in school time. Survives a failed refresh, because
  /// it describes the data still on screen.
  final SchoolTime? observedAt;

  /// Whether any load has completed. Distinguishes "no children yet" from "no children" —
  /// an empty dashboard before the first response is a spinner, not an empty state.
  final bool hasLoadedOnce;

  /// Whether the last failure means the device could not reach the platform.
  ///
  /// Drives the cached-data banner rather than the error screen: PARENT_APP.md requires
  /// last-known state with a freshness label when offline, never a blank screen.
  bool get isDisconnected =>
      failure?.code == ErrorCode.dependencyUnavailable;

  /// Whether to replace the content with an error, rather than banner it.
  ///
  /// Only when there is nothing to show. With cards on screen, an error is a banner above
  /// data the parent can still read — throwing that away to display a failure would be the
  /// stale-versus-nothing trade decided the wrong way.
  bool get showsFailureInsteadOfContent => failure != null && children.isEmpty;

  HomeState copyWith({
    List<ChildStatus>? children,
    bool? isLoading,
    Failure<void>? failure,
    bool clearFailure = false,
    SchoolTime? observedAt,
    bool? hasLoadedOnce,
  }) {
    return HomeState(
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      observedAt: observedAt ?? this.observedAt,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  List<Object?> get props => [
        children,
        isLoading,
        failure?.code,
        observedAt,
        hasLoadedOnce,
      ];
}
