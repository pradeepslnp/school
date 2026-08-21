import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../repository/models/notification_item.dart';

/// One row of the notification centre.
///
/// Critical and urgent items are visually distinct and unread stays bold — color is never
/// the only signal, so an icon and weight carry the same information
/// (docs/05-ui/ACCESSIBILITY.md).
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.priority) {
      NotificationPriority.critical => (
        Icons.warning_amber_rounded,
        context.status.critical,
      ),
      NotificationPriority.urgent => (
        Icons.error_outline,
        context.status.warning,
      ),
      NotificationPriority.standard => (
        Icons.info_outline,
        context.status.info,
      ),
      NotificationPriority.info => (
        Icons.circle_notifications_outlined,
        context.status.neutral,
      ),
    };

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        item.title,
        style: context.texts.bodyLarge?.copyWith(
          fontWeight: item.isRead ? FontWeight.normal : FontWeight.w700,
        ),
      ),
      subtitle: Text(
        [
          if (item.studentDisplayName != null) item.studentDisplayName!,
          item.occurredAt.timeOfDay,
        ].join(' · '),
        style: context.texts.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      trailing: item.isRead
          ? null
          : Container(
              width: AppSizeConstants.unreadDotDiameter,
              height: AppSizeConstants.unreadDotDiameter,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
    );
  }
}
