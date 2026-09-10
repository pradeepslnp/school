import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../guardians/bloc/student_guardians_bloc.dart';
import '../bloc/student_custody_bloc.dart';
import '../bloc/student_custody_event.dart';
import '../bloc/student_custody_state.dart';
import '../domain/custody_restriction_models.dart';

/// A-14 — Custody restrictions panel on the student record.
///
/// Deliberately set apart from the rest of the screen: an error-toned card, an explicit warning
/// that a restriction takes effect immediately and overrides guardian rights, and a required
/// reason on every one (BR-GRD-008 🔴). Rendered only for `PERM-CUSTODY-RESTRICTION-MANAGE`
/// holders — the parent app has no equivalent and must never gain one.
class CustodyRestrictionPanel extends StatelessWidget {
  const CustodyRestrictionPanel({super.key, required this.studentId});

  final String studentId;

  Future<void> _openAdd(BuildContext context) async {
    final custodyBloc = context.read<StudentCustodyBloc>();
    final guardians = context.read<StudentGuardiansBloc>().state.guardians;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: custodyBloc,
        child: _AddRestrictionDialog(
          studentId: studentId,
          guardians: guardians
              .map((g) => (id: g.guardianId, name: '${g.firstName} ${g.lastName}'.trim()))
              .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _confirmLift(BuildContext context, CustodyRestriction restriction) async {
    final bloc = context.read<StudentCustodyBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.custodyLiftConfirmTitle),
        content: Text(context.l10n.custodyLiftConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.custodyLiftConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(CustodyRestrictionLifted(studentId: studentId, restrictionId: restriction.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<StudentCustodyBloc, StudentCustodyState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Card(
        elevation: 0,
        color: scheme.errorContainer.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.sm),
          side: BorderSide(color: scheme.error),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, color: scheme.error, size: 20),
                  const SizedBox(width: AdminSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.custodyPanelTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('custody_add_button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    onPressed: () => _openAdd(context),
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.custodyAddButton),
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.sm),
              Text(
                context.l10n.custodyPanelWarning,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
              ),
              const SizedBox(height: AdminSpacing.md),
              BlocBuilder<StudentCustodyBloc, StudentCustodyState>(
                builder: (context, state) {
                  if (state.isLoading && state.restrictions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AdminSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: context.l10n.custodyLoadingLabel,
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                          child: Text(
                            _errorText(context, state.error!),
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                          ),
                        ),
                      if (state.restrictions.isEmpty)
                        Text(
                          context.l10n.custodyEmptyState,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      else
                        for (final restriction in state.restrictions)
                          _RestrictionTile(
                            restriction: restriction,
                            subjectLabel: _subjectLabel(context, restriction),
                            onLift: () => _confirmLift(context, restriction),
                          ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A named person shows their name; a restricted guardian is resolved against the parents
  /// panel's list, falling back to a short id when that guardian is no longer on the list.
  static String _subjectLabel(BuildContext context, CustodyRestriction restriction) {
    if (restriction.restrictedPersonName != null) return restriction.restrictedPersonName!;
    final id = restriction.restrictedGuardianId ?? '';
    final guardians = context.read<StudentGuardiansBloc>().state.guardians;
    for (final g in guardians) {
      if (g.guardianId == id) return '${g.firstName} ${g.lastName}'.trim();
    }
    return context.l10n.custodySubjectGuardian(id.length > 8 ? id.substring(0, 8) : id);
  }

  static String _errorText(BuildContext context, ErrorCode code) {
    final l10n = context.l10n;
    return switch (code) {
      ErrorCode.custodyRestrictionSubjectRequired => l10n.custodyErrorSubjectRequired,
      ErrorCode.custodyRestrictionNotFound => l10n.custodyErrorNotFound,
      ErrorCode.validationRequiredFieldMissing => l10n.custodyErrorReasonRequired,
      ErrorCode.dependencyUnavailable => l10n.errorApiUnreachable,
      ErrorCode.authSessionRevoked ||
      ErrorCode.authRefreshReuseDetected => l10n.errorSessionEnded,
      _ => l10n.errorGenericRetryShortly,
    };
  }
}

String custodyTypeLabel(BuildContext context, String wire) => switch (wire) {
      'NO_HANDOVER' => context.l10n.custodyTypeNoHandover,
      'NO_VISIBILITY' => context.l10n.custodyTypeNoVisibility,
      'FULL' => context.l10n.custodyTypeFull,
      _ => wire,
    };

class _RestrictionTile extends StatelessWidget {
  const _RestrictionTile({
    required this.restriction,
    required this.subjectLabel,
    required this.onLift,
  });

  final CustodyRestriction restriction;
  final String subjectLabel;
  final VoidCallback onLift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subject = subjectLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AdminSpacing.xs),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$subject · ${custodyTypeLabel(context, restriction.restrictionType)}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (restriction.active)
                TextButton(
                  key: Key('custody_lift_${restriction.id}'),
                  onPressed: onLift,
                  child: Text(context.l10n.custodyLiftButton),
                )
              else
                Text(
                  context.l10n.custodyStatusLifted,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AdminSpacing.xs),
          Text(restriction.reason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AdminSpacing.xs),
          Text(
            context.l10n.custodyEffectiveLine(
              _date(restriction.effectiveFrom),
              restriction.effectiveUntil == null
                  ? context.l10n.custodyOpenEnded
                  : _date(restriction.effectiveUntil!),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _AddRestrictionDialog extends StatefulWidget {
  const _AddRestrictionDialog({required this.studentId, required this.guardians});

  final String studentId;
  final List<({String id, String name})> guardians;

  @override
  State<_AddRestrictionDialog> createState() => _AddRestrictionDialogState();
}

class _AddRestrictionDialogState extends State<_AddRestrictionDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _subjectIsGuardian = true;
  String? _guardianId;
  final _personName = TextEditingController();
  final _reason = TextEditingController();
  final _until = TextEditingController();
  CustodyRestrictionType _type = CustodyRestrictionType.noHandover;

  @override
  void initState() {
    super.initState();
    _subjectIsGuardian = widget.guardians.isNotEmpty;
    _guardianId = widget.guardians.isNotEmpty ? widget.guardians.first.id : null;
  }

  @override
  void dispose() {
    _personName.dispose();
    _reason.dispose();
    _until.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final useGuardian = _subjectIsGuardian && widget.guardians.isNotEmpty;
    context.read<StudentCustodyBloc>().add(
          CustodyRestrictionRecorded(
            studentId: widget.studentId,
            restrictedGuardianId: useGuardian ? _guardianId : null,
            restrictedPersonName: useGuardian ? null : _personName.text.trim(),
            restrictionType: _type.wire,
            reason: _reason.text.trim(),
            effectiveUntil: _until.text.trim().isEmpty ? null : '${_until.text.trim()}T00:00:00Z',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasGuardians = widget.guardians.isNotEmpty;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: BlocBuilder<StudentCustodyBloc, StudentCustodyState>(
            builder: (context, state) => Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.custodyAddTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AdminSpacing.md),
                  if (hasGuardians) ...[
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: true, label: Text(l10n.custodySubjectAGuardian)),
                        ButtonSegment(value: false, label: Text(l10n.custodySubjectAPerson)),
                      ],
                      selected: {_subjectIsGuardian},
                      onSelectionChanged: (s) =>
                          setState(() => _subjectIsGuardian = s.first),
                    ),
                    const SizedBox(height: AdminSpacing.md),
                    if (_subjectIsGuardian)
                      DropdownButtonFormField<String>(
                        initialValue: _guardianId,
                        decoration: InputDecoration(labelText: l10n.custodyGuardianLabel),
                        items: [
                          for (final g in widget.guardians)
                            DropdownMenuItem(value: g.id, child: Text(g.name)),
                        ],
                        onChanged: (v) => setState(() => _guardianId = v),
                      ),
                  ],
                  if (!_subjectIsGuardian || !hasGuardians)
                    TextFormField(
                      controller: _personName,
                      decoration: InputDecoration(labelText: l10n.custodyPersonNameLabel),
                      validator: (v) => (!_subjectIsGuardian || !hasGuardians) &&
                              (v == null || v.trim().isEmpty)
                          ? l10n.custodyPersonNameRequired
                          : null,
                    ),
                  const SizedBox(height: AdminSpacing.md),
                  DropdownButtonFormField<CustodyRestrictionType>(
                    initialValue: _type,
                    decoration: InputDecoration(labelText: l10n.custodyTypeLabel),
                    items: [
                      for (final t in CustodyRestrictionType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(custodyTypeLabel(context, t.wire)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: AdminSpacing.md),
                  TextFormField(
                    controller: _reason,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.custodyReasonLabel,
                      helperText: l10n.custodyReasonHelper,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.custodyErrorReasonRequired : null,
                  ),
                  const SizedBox(height: AdminSpacing.md),
                  TextFormField(
                    controller: _until,
                    decoration: InputDecoration(
                      labelText: l10n.custodyUntilLabel,
                      hintText: 'YYYY-MM-DD',
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t)
                          ? null
                          : l10n.custodyUntilFormatError;
                    },
                  ),
                  const SizedBox(height: AdminSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.commonCancelButton),
                      ),
                      const SizedBox(width: AdminSpacing.sm),
                      FilledButton(
                        key: const Key('custody_submit_button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        ),
                        onPressed: state.isSubmitting ? null : _submit,
                        child: Text(l10n.custodyAddSubmitButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
