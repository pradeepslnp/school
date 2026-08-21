part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => const [];
}

final class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

final class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}

/// The parent opened an entry — its acknowledgement (docs/05-ui/PARENT_APP.md: "stay unread
/// until acknowledged").
final class NotificationsItemOpened extends NotificationsEvent {
  const NotificationsItemOpened(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}
