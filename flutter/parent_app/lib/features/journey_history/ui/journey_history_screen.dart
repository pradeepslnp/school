import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../../../utils/utils.dart';
import '../repository/models/journey_history_entry.dart';
import '../widgets/journey_history_entry_tile.dart';

/// P-05 — the durable record of a child's past journeys.
///
/// Renders state it is given; it does not fetch (ENGINEERING_PRINCIPLES.md §8). Grouped by
/// day, newest first — the same rule P-08 uses for notifications
/// (docs/05-ui/PARENT_APP.md) — so a parent scanning back finds "yesterday afternoon" as
/// fast as they would scroll a message thread.
class JourneyHistoryScreen extends StatelessWidget {
  const JourneyHistoryScreen({
    super.key,
    required this.children,
    this.selected,
    this.entries = const <JourneyHistoryEntry>[],
    this.isLoading = false,
    this.loadFailure,
    this.onRefresh,
    this.onChildSelected,
  });

  final List<ChildOption> children;
  final ChildOption? selected;
  final List<JourneyHistoryEntry> entries;
  final bool isLoading;
  final String? loadFailure;
  final Future<void> Function()? onRefresh;
  final void Function(ChildOption)? onChildSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.journeyHistoryAppBarTitle)),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (children.isEmpty) {
      return _Message(
        icon: Icons.family_restroom,
        title: context.l10n.noChildrenLinkedTitle,
        detail: context.l10n.noChildrenLinkedDetail,
      );
    }

    final grouped = _groupByDay(entries);

    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (children.length > 1)
          SliverToBoxAdapter(
            child: ReadableWidth(
              child: Padding(
                padding: const EdgeInsets.all(GuardianSpacing.md),
                child: _ChildSelector(
                  children: children,
                  selected: selected,
                  onChanged: onChildSelected,
                ),
              ),
            ),
          ),
        if (isLoading && entries.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (loadFailure != null && entries.isEmpty)
          SliverFillRemaining(
            child: _Message(
              icon: Icons.cloud_off,
              title: context.l10n.journeyHistoryLoadFailureTitle,
              detail: loadFailure!,
              onRetry: onRefresh,
            ),
          )
        else if (entries.isEmpty)
          SliverFillRemaining(
            child: _Message(
              icon: Icons.history,
              title: context.l10n.journeyHistoryEmptyTitle,
              detail: context.l10n.journeyHistoryEmptyDetail,
            ),
          )
        else
          SliverList.builder(
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final day = grouped[index];
              return ReadableWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GuardianSpacing.md,
                    GuardianSpacing.sm,
                    GuardianSpacing.md,
                    GuardianSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dayLabel(context, day.date), style: context.texts.titleMedium),
                      Card(
                        margin: const EdgeInsets.only(top: GuardianSpacing.xs),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GuardianSpacing.md,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < day.entries.length; i++) ...[
                                if (i > 0) const Divider(),
                                JourneyHistoryEntryTile(entry: day.entries[i]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );

    if (onRefresh == null) return content;
    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }

  static List<_Day> _groupByDay(List<JourneyHistoryEntry> entries) {
    final byDate = <DateTime, List<JourneyHistoryEntry>>{};
    for (final entry in entries) {
      final key = DateTime.utc(
        entry.serviceDate.year,
        entry.serviceDate.month,
        entry.serviceDate.day,
      );
      byDate.putIfAbsent(key, () => []).add(entry);
    }
    final days = byDate.entries.map((e) => _Day(e.key, e.value)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  /// Weekday and month names come from `intl`'s locale-aware [intl.DateFormat] rather than a
  /// hand-keyed ARB entry per weekday/month: `intl` is already a dependency for this
  /// localisation pass (ADR-0013), and calendar names are exactly what it exists to format —
  /// duplicating them as translatable resource strings would be reinventing what the package
  /// already provides correctly per locale.
  static String _dayLabel(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return l10n.dayLabelToday;
    if (diff == 1) return l10n.dayLabelYesterday;

    final localeName = Localizations.localeOf(context).toString();
    if (diff < 7) return intl.DateFormat.EEEE(localeName).format(date);
    return intl.DateFormat('EEEE, d MMM', localeName).format(date);
  }
}

class _Day {
  const _Day(this.date, this.entries);

  final DateTime date;
  final List<JourneyHistoryEntry> entries;
}

class _ChildSelector extends StatelessWidget {
  const _ChildSelector({required this.children, this.selected, this.onChanged});

  final List<ChildOption> children;
  final ChildOption? selected;
  final void Function(ChildOption)? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ChildOption>(
      value: selected,
      decoration: InputDecoration(labelText: context.l10n.whichChildLabel),
      items: [
        for (final child in children)
          DropdownMenuItem(value: child, child: Text(child.displayName)),
      ],
      onChanged: onChanged == null
          ? null
          : (value) {
              if (value != null) onChanged!(value);
            },
    );
  }
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
