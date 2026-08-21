import 'package:flutter/foundation.dart';

import '../../../../core/domain.dart';

/// The four priority classes from [`NOTIFICATION_CATALOG.md`]. Only [critical] is exempt
/// from preferences and quiet hours (BR-NTF-006) — the rest merely differ in how visually
/// insistent this screen makes them.
enum NotificationPriority { critical, urgent, standard, info }

/// One entry in P-08, the durable notification record.
///
/// "A parent who missed a push must be able to scroll back and find it"
/// (docs/05-ui/PARENT_APP.md) — this is that record, not the push itself.
@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.catalogId,
    required this.priority,
    required this.title,
    required this.occurredAt,
    this.isRead = false,
    this.studentDisplayName,
  });

  final String id;

  /// `NTF-<AREA>-<nn>` — the catalog entry this came from.
  final String catalogId;

  final NotificationPriority priority;

  /// Complete in one line, readable from a lock screen (`NOTIFICATION_CATALOG.md` Copy
  /// Principle 1) — there is deliberately no separate body field to truncate.
  final String title;

  final SchoolTime occurredAt;

  /// Stays unread until acknowledged if [priority] is [NotificationPriority.critical]
  /// (docs/05-ui/PARENT_APP.md) — enforced by the BLoC, not this field.
  final bool isRead;

  /// Which child this concerns, for display only. Never another family's
  /// (BR-NTF-007 🔴) — the dummy backend never fabricates one.
  final String? studentDisplayName;
}
