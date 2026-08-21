part of 'child_detail_bloc.dart';

final class ChildDetailState extends Equatable {
  const ChildDetailState({
    required this.studentId,
    this.detail,
    this.isLoading = false,
    this.failure,
  });

  /// Whose detail this is. Fixed for the lifetime of the BLoC — a different child means a
  /// new route, not a mutation of this one (docs/06-development/PROJECT_STRUCTURE.md: the
  /// route owns wiring for one feature instance).
  final String studentId;

  final ChildDetail? detail;
  final bool isLoading;
  final Failure<void>? failure;

  /// Whether to replace the content with an error rather than banner it — only once there
  /// is nothing to show yet, mirroring HomeState.
  bool get showsFailureInsteadOfContent => failure != null && detail == null;

  ChildDetailState copyWith({
    ChildDetail? detail,
    bool? isLoading,
    Failure<void>? failure,
    bool clearFailure = false,
  }) {
    return ChildDetailState(
      studentId: studentId,
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [studentId, detail, isLoading, failure?.code];
}
