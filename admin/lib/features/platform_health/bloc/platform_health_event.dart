import 'package:equatable/equatable.dart';

/// What the operator did on the Platform health screen (A-62).
sealed class PlatformHealthEvent extends Equatable {
  const PlatformHealthEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown, or the operator asked to refresh — one event either way, matching
/// `OrganizationListEvent`'s discipline: a fresh load and a manual refresh do exactly the
/// same thing here, so there is no separate "refresh" event that would duplicate it.
final class PlatformHealthRequested extends PlatformHealthEvent {
  const PlatformHealthRequested();
}
