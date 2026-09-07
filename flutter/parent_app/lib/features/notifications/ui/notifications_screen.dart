import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/l10n_extensions.dart';
import '../../../utils/utils.dart';
import '../repository/models/notification_item.dart';
import '../widgets/notification_tile.dart';

/// P-08 — the notification centre, the durable record of what this app has told the parent.
///
/// Renders state it is given; it does not fetch (ENGINEERING_PRINCIPLES.md §8). Grouped by
/// day, newest first (docs/05-ui/PARENT_APP.md).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    this.items = const <NotificationItem>[],
    this.isLoading = false,
    this.loadFailure,
    this.onRefresh,
    required this.onItemTapped,
  });

  final List<NotificationItem> items;
  final bool isLoading;
  final String? loadFailure;
  final Future<void> Function()? onRefresh;
  final void Function(String notificationId) onItemTapped;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notificationsAppBarTitle)),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadFailure != null && items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off,
        title: context.l10n.notificationsLoadFailureTitle,
        detail: loadFailure!,
        onRetry: onRefresh,
      );
    }

    if (items.isEmpty) {
      return _Message(
        icon: Icons.notifications_none,
        title: context.l10n.notificationsEmptyTitle,
        detail: context.l10n.notificationsEmptyDetail,
      );
    }

    final grouped = _groupByDay(items);

    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (final day in grouped) ...[
          SliverToBoxAdapter(
            child: ReadableWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  GuardianSpacing.md,
                  GuardianSpacing.md,
                  GuardianSpacing.md,
                  GuardianSpacing.xs,
                ),
                child: Text(_dayLabel(context, day.date), style: context.texts.titleMedium),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: day.items.length,
            itemBuilder: (context, index) {
              final item = day.items[index];
              return ReadableWidth(
                child: NotificationTile(
                  item: item,
                  onTap: () => onItemTapped(item.id),
                ),
              );
            },
          ),
        ],
      ],
    );

    if (onRefresh == null) return content;
    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }

  static List<_Day> _groupByDay(List<NotificationItem> items) {
    final byDate = <DateTime, List<NotificationItem>>{};
    for (final item in items) {
      final v = item.occurredAt.value;
      final key = DateTime(v.year, v.month, v.day);
      byDate.putIfAbsent(key, () => []).add(item);
    }
    final days = byDate.entries.map((e) => _Day(e.key, e.value)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  /// Weekday names come from `intl`'s locale-aware [intl.DateFormat] rather than a hand-keyed
  /// ARB entry per weekday — see the identical decision and rationale in
  /// journey_history_screen.dart's `_dayLabel`.
  static String _dayLabel(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return l10n.dayLabelToday;
    if (diff == 1) return l10n.dayLabelYesterday;
    if (diff < 7) {
      final localeName = Localizations.localeOf(context).toString();
      return intl.DateFormat.EEEE(localeName).format(date);
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _Day {
  const _Day(this.date, this.items);

  final DateTime date;
  final List<NotificationItem> items;
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GuardianSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizeConstants.emptyStateIcon, color: context.colors.onSurfaceVariant),
            const SizedBox(height: GuardianSpacing.md),
            Text(title, style: context.texts.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: GuardianSpacing.sm),
            Text(
              detail,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: GuardianSpacing.lg),
              FilledButton.tonal(
                onPressed: () => onRetry!(),
                child: Text(context.l10n.tryAgainButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
