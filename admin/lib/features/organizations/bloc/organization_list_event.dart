import 'package:equatable/equatable.dart';

/// What the operator did on the Organizations list screen (A-41).
sealed class OrganizationListEvent extends Equatable {
  const OrganizationListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown, or the operator asked to refresh — same request either way, matching
/// `LoginEvent`'s discipline of one event per distinct thing the operator did rather than a
/// separate "refresh" event that would do nothing a fresh load doesn't already do.
final class OrganizationListRequested extends OrganizationListEvent {
  const OrganizationListRequested();
}
