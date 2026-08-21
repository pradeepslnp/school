part of 'handover_bloc.dart';

final class HandoverState extends Equatable {
  const HandoverState({
    this.children = const <ChildOption>[],
    this.selected,
    this.code,
    this.isLoading = false,
    this.failure,
  });

  final List<ChildOption> children;
  final ChildOption? selected;

  /// The live code for [selected], once requested successfully.
  final HandoverCode? code;

  final bool isLoading;
  final Failure<void>? failure;

  bool get showsFailureInsteadOfContent => failure != null && code == null;

  HandoverState copyWith({
    List<ChildOption>? children,
    ChildOption? selected,
    HandoverCode? code,
    bool clearCode = false,
    bool? isLoading,
    Failure<void>? failure,
    bool clearFailure = false,
  }) {
    return HandoverState(
      children: children ?? this.children,
      selected: selected ?? this.selected,
      code: clearCode ? null : (code ?? this.code),
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props =>
      [children, selected, code?.code, code?.expiresAt, isLoading, failure?.code];
}
