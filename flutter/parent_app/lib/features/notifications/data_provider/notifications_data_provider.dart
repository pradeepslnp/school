import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for P-08, the notification centre.
///
/// Contract: `GET /notifications/me`, `POST /notifications/{id}/read`
/// (docs/04-api/TRACKING_NOTIFICATION_API.md § Notifications), served by MOD-12.
///
/// `/me` takes no identifier: an endpoint that accepted a user id would be an endpoint that
/// could be asked about somebody else's messages, which on this platform means somebody
/// else's child (BR-NTF-007).
class NotificationsDataProvider {
  NotificationsDataProvider({required this.client});

  final RestClient client;

  Future<ApiResponse> fetchNotifications() => client.get('/notifications/me');

  /// Acknowledges one entry.
  ///
  /// Answers `204` whether or not anything changed — already read, unknown id, someone else's
  /// id are deliberately indistinguishable. Marking read is idempotent, so this POST is safe
  /// to retry; it is given no idempotency key because there is nothing to deduplicate.
  Future<ApiResponse> markRead({required String notificationId}) =>
      client.post('/notifications/$notificationId/read');
}
