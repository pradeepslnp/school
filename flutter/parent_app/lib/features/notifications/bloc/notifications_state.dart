part of 'notifications_bloc.dart';

final class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const <NotificationItem>[],
    this.isLoading = false,
    this.failure,
  });

  final List<NotificationItem> items;
  final bool isLoading;
  final Failure<void>? failure;

  bool get showsFailureInsteadOfContent => failure != null && items.isEmpty;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    Failure<void>? failure,
    bool clearFailure = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [items, isLoading, failure?.code];
}
