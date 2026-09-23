import 'package:equatable/equatable.dart';

/// What the crew did on a run's manifest (BRD-001..004).
sealed class ManifestEvent extends Equatable {
  const ManifestEvent();

  @override
  List<Object?> get props => const [];
}

final class ManifestRequested extends ManifestEvent {
  const ManifestRequested();
}

/// The crew recorded a child getting on or off.
///
/// One event for both directions rather than two: the screen offers exactly one action per child
/// based on where they are, so the direction is a property of the tap, not a separate decision.
final class BoardingRecorded extends ManifestEvent {
  const BoardingRecorded({
    required this.studentId,
    required this.isBoarding,
    this.overrideReason,
  });

  final String studentId;
  final bool isBoarding;

  /// Present only when the crew is knowingly going against the manifest — a child at the wrong
  /// stop, or one not on the list. Never defaulted: an override without a reason is not evidence
  /// (BR-AUD-004).
  final String? overrideReason;

  @override
  List<Object?> get props => [studentId, isBoarding, overrideReason];
}
