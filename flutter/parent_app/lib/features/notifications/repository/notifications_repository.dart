import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/notifications_data_provider.dart';
import 'models/notification_item.dart';

/// Turns notification transport into domain meaning.
///
/// The BLoC depends on this, never on [NotificationsDataProvider]
/// (ENGINEERING_PRINCIPLES.md §4).
class NotificationsRepository {
  NotificationsRepository({required this.dataProvider});

  final NotificationsDataProvider dataProvider;

  Future<Result<List<NotificationItem>>> fetchNotifications() async {
    final response = await dataProvider.fetchNotifications();
    if (!response.isSuccess) return _toFailure<List<NotificationItem>>(response);

    final zone = _SchoolZone.parse(response.body);

    final items = response.dataList
        .whereType<Map<String, Object?>>()
        .map((raw) => _parse(raw, zone))
        .whereType<NotificationItem>()
        .toList(growable: false)
      // Newest first (docs/05-ui/PARENT_APP.md P-08).
      ..sort((a, b) => b.occurredAt.value.compareTo(a.occurredAt.value));

    return Success<List<NotificationItem>>(items);
  }

  Future<Result<void>> markRead({required String notificationId}) async {
    final response = await dataProvider.markRead(notificationId: notificationId);
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  static NotificationItem? _parse(Map<String, Object?> raw, _SchoolZone zone) {
    final id = raw['id'] as String?;
    final catalogId = raw['catalogId'] as String?;
    final title = raw['title'] as String?;
    final occurredAt = zone.at(_utc(raw['occurredAt']));
    if (id == null || catalogId == null || title == null || occurredAt == null) return null;

    return NotificationItem(
      id: id,
      catalogId: catalogId,
      priority: _parsePriority(raw['priority'] as String?),
      title: title,
      occurredAt: occurredAt,
      isRead: raw['isRead'] as bool? ?? false,
      studentDisplayName: raw['studentDisplayName'] as String?,
    );
  }

  static NotificationPriority _parsePriority(String? wire) {
    return switch (wire) {
      'CRITICAL' => NotificationPriority.critical,
      'URGENT' => NotificationPriority.urgent,
      'STANDARD' => NotificationPriority.standard,
      // An unrecognised value is treated as the quietest class, never promoted — the
      // catalog is the single source of truth for what deserves attention, and a client
      // that has not shipped a new class yet should under-react, not over-react.
      _ => NotificationPriority.info,
    };
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return const Failure(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
    );
  }

  static DateTime? _utc(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}

/// The school's clock, read once from the response envelope (BR-CFG-006).
class _SchoolZone {
  const _SchoolZone({required this.timezoneId, required this.offset});

  final String timezoneId;
  final Duration offset;

  static _SchoolZone parse(Map<String, Object?> body) {
    final meta = body['meta'] as Map<String, Object?>? ?? const {};
    final school = meta['school'] as Map<String, Object?>? ?? const {};
    final minutes = school['utcOffsetMinutes'];

    return _SchoolZone(
      timezoneId: school['timezoneId'] as String? ?? 'UTC',
      offset: minutes is num ? Duration(minutes: minutes.round()) : Duration.zero,
    );
  }

  SchoolTime? at(DateTime? utc) =>
      utc == null ? null : SchoolTime.fromUtc(utc, timezoneId: timezoneId, offset: offset);
}
