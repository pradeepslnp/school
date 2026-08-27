import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../bloc/audit_list_bloc.dart';
import '../bloc/audit_list_event.dart';
import '../bloc/audit_list_state.dart';
import '../domain/audit_models.dart';

/// A-54 / A-55 — the audit trail and the override register.
///
/// Read-only, always: an audit record is written server-side in the same transaction as the
/// change it describes (BR-AUD-002), so there is no create, edit, or delete path here. The one
/// control is the [SegmentedButton] that switches between the full trail (A-54) and the subset
/// that carries an override reason (A-55).
///
/// Matching `UserListScreen`: no decisions here, only rendering and reporting. The screen holds
/// no local mutable state of its own — which view is showing lives in [AuditListState], so a
/// refresh or a rebuild can never disagree with the toggle.
class AuditListScreen extends StatelessWidget {
  const AuditListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Audit trail', style: theme.textTheme.headlineSmall)),
              BlocBuilder<AuditListBloc, AuditListState>(
                buildWhen: (previous, current) =>
                    previous.overridesOnly != current.overridesOnly ||
                    previous.isLoading != current.isLoading,
                builder: (context, state) {
                  return SegmentedButton<bool>(
                    key: const Key('audit_scope_toggle'),
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('All activity'),
                        icon: Icon(Icons.list_alt_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Overrides'),
                        icon: Icon(Icons.gpp_maybe_outlined),
                      ),
                    ],
                    selected: {state.overridesOnly},
                    onSelectionChanged: state.isLoading
                        ? null
                        : (selection) {
                            final overridesOnly = selection.first;
                            if (overridesOnly == state.overridesOnly) return;
                            context
                                .read<AuditListBloc>()
                                .add(AuditRequested(overridesOnly: overridesOnly));
                          },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          BlocBuilder<AuditListBloc, AuditListState>(
            buildWhen: (previous, current) => previous.overridesOnly != current.overridesOnly,
            builder: (context, state) {
              return Text(
                state.overridesOnly
                    ? 'Actions taken with an override reason — a person overrode a safety check and said why.'
                    : 'Every safety-relevant action, most recent first. Records cannot be edited or removed.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(height: AdminSpacing.lg),
          Expanded(
            child: BlocBuilder<AuditListBloc, AuditListState>(
              builder: (context, state) {
                if (state.isLoading && state.records.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(semanticsLabel: 'Loading audit trail'),
                  );
                }

                if (state.error != null && state.records.isEmpty) {
                  final color = context.status.critical;
                  return Center(
                    child: Text(
                      'The audit trail could not be loaded right now. Try again.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  );
                }

                if (state.records.isEmpty) {
                  return Center(
                    child: Text(
                      state.overridesOnly
                          ? 'No overrides recorded. That is the healthy state.'
                          : 'No activity recorded yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return _AuditTable(records: state.records);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.records});

  final List<AuditRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        key: const Key('audit_list_table'),
        itemCount: records.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _AuditRow(record: records[index]),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.record});

  final AuditRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      record.subjectType,
      if (record.actorRole != null && record.actorRole!.isNotEmpty)
        _roleLabel(record.actorRole!)
      else
        record.actorType,
      _formatWhen(record.occurredAt),
    ];

    return ListTile(
      key: Key('audit_list_row_${record.id}'),
      minVerticalPadding: AdminSpacing.md,
      leading: Icon(
        record.isOverride ? Icons.gpp_maybe_outlined : Icons.history,
        color: record.isOverride ? context.status.warning : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(record.actionLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitleParts.join(' · ')),
          if (record.isOverride)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Reason: ${record.reason}',
                style: theme.textTheme.bodySmall?.copyWith(color: context.status.warning),
              ),
            ),
        ],
      ),
      trailing: record.isOverride
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AdminSpacing.sm),
                border: Border.all(color: context.status.warning),
              ),
              child: Text(
                'Override',
                style: theme.textTheme.labelSmall?.copyWith(color: context.status.warning),
              ),
            )
          : null,
      isThreeLine: record.isOverride,
    );
  }

  /// `SCHOOL_ADMIN` reads as "School admin" — same title-casing the action code gets, so a role
  /// code never leaks raw into the UI.
  static String _roleLabel(String roleCode) {
    final words = roleCode.toLowerCase().replaceAll('_', ' ').trim();
    if (words.isEmpty) return roleCode;
    return words[0].toUpperCase() + words.substring(1);
  }

  /// A calendar timestamp, not "3 minutes ago" — an audit trail is a legal record, so the exact
  /// wall-clock moment is what matters, and relative time would drift every rebuild.
  static String _formatWhen(DateTime when) {
    final local = when.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }
}
