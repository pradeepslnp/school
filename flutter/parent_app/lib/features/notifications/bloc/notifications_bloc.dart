import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../repository/models/notification_item.dart';
import '../repository/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// P-08 decisions: what the list shows and when an entry counts as acknowledged. Depends on
/// [NotificationsRepository], never on the data provider (ENGINEERING_PRINCIPLES.md §4).
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required this.repository}) : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsRefreshed>(_onStarted);
    on<NotificationsItemOpened>(_onItemOpened);
  }

  final NotificationsRepository repository;

  Future<void> _onStarted(
    NotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));

    final result = await repository.fetchNotifications();

    switch (result) {
      case Success<List<NotificationItem>>(:final value):
        emit(state.copyWith(isLoading: false, items: value));
      case Failure<List<NotificationItem>>(:final code, :final messageKey):
        emit(
          state.copyWith(
            isLoading: false,
            failure: Failure<void>(code, messageKey: messageKey),
          ),
        );
    }
  }

  Future<void> _onItemOpened(
    NotificationsItemOpened event,
    Emitter<NotificationsState> emit,
  ) async {
    final target = state.items.where((n) => n.id == event.notificationId).firstOrNull;
    if (target == null || target.isRead) return;

    // Marked optimistically: the durable record is more useful open than technically
    // correct for the half-second a round trip takes, and a failure here does not change
    // anything the parent needs to act on.
    emit(
      state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == event.notificationId)
              NotificationItem(
                id: item.id,
                catalogId: item.catalogId,
                priority: item.priority,
                title: item.title,
                occurredAt: item.occurredAt,
                isRead: true,
                studentDisplayName: item.studentDisplayName,
              )
            else
              item,
        ],
      ),
    );

    await repository.markRead(notificationId: event.notificationId);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
