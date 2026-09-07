import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../../../utils/utils.dart';
import '../bloc/pickup_persons_bloc.dart';
import '../repository/models/pickup_person.dart';

/// P-07 — authorised pickup persons.
///
/// Renders state it is given and emits events; it decides nothing itself
/// (ENGINEERING_PRINCIPLES.md §8). Custody restrictions are never displayed here or
/// anywhere in this app (docs/05-ui/PARENT_APP.md) — this screen has no field for them and
/// never will.
class PickupPersonsScreen extends StatelessWidget {
  const PickupPersonsScreen({
    super.key,
    required this.state,
    required this.onChildSelected,
    required this.onAddFormToggled,
    required this.onFullNameChanged,
    required this.onPhoneChanged,
    required this.onRelationshipChanged,
    required this.onValidityChanged,
    required this.onSubmit,
    required this.onRevoke,
  });

  final PickupPersonsState state;
  final void Function(ChildOption) onChildSelected;
  final void Function(bool show) onAddFormToggled;
  final void Function(String) onFullNameChanged;
  final void Function(String) onPhoneChanged;
  final void Function(String) onRelationshipChanged;
  final void Function(DateTime from, DateTime until) onValidityChanged;
  final VoidCallback onSubmit;
  final void Function(String pickupPersonId) onRevoke;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pickupPersonsAppBarTitle)),
      floatingActionButton: state.children.isEmpty || state.showAddForm
          ? null
          : FloatingActionButton.extended(
              onPressed: () => onAddFormToggled(true),
              icon: const Icon(Icons.person_add_alt),
              label: Text(context.l10n.pickupPersonsAddButton),
            ),
      body: SafeArea(
        child: state.children.isEmpty
            ? const _NoChildren()
            : ReadableWidth(
                child: ListView(
                  padding: const EdgeInsets.all(GuardianSpacing.md),
                  children: [
                    if (state.children.length > 1) ...[
                      Text(context.l10n.whichChildLabel, style: context.texts.titleMedium),
                      const SizedBox(height: GuardianSpacing.sm),
                      DropdownButtonFormField<ChildOption>(
                        value: state.selectedChild,
                        items: [
                          for (final child in state.children)
                            DropdownMenuItem(value: child, child: Text(child.displayName)),
                        ],
                        onChanged: (value) {
                          if (value != null) onChildSelected(value);
                        },
                      ),
                      const SizedBox(height: GuardianSpacing.lg),
                    ],
                    if (state.submitFailure != null) ...[
                      _ErrorBanner(failure: state.submitFailure!),
                      const SizedBox(height: GuardianSpacing.md),
                    ],
                    if (state.showAddForm) ...[
                      _AddForm(
                        state: state,
                        onFullNameChanged: onFullNameChanged,
                        onPhoneChanged: onPhoneChanged,
                        onRelationshipChanged: onRelationshipChanged,
                        onValidityChanged: onValidityChanged,
                        onSubmit: onSubmit,
                        onCancel: () => onAddFormToggled(false),
                      ),
                      const SizedBox(height: GuardianSpacing.lg),
                    ],
                    if (state.isLoadingList && state.people.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: GuardianSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    // A failed load is never presented as "nobody authorised" — that reads
                    // as reassuring when it means the opposite: the app does not actually
                    // know.
                    else if (state.listFailure != null && state.people.isEmpty)
                      _ErrorBanner(failure: state.listFailure!)
                    else if (state.people.isEmpty)
                      Text(
                        context.l10n.pickupPersonsNoneAuthorised,
                        style: context.texts.bodyMedium
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      )
                    else
                      for (final person in state.people)
                        _PickupPersonCard(
                          person: person,
                          onRevoke: () => onRevoke(person.id),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PickupPersonCard extends StatelessWidget {
  const _PickupPersonCard({required this.person, required this.onRevoke});

  final PickupPerson person;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final expired = person.isExpired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GuardianSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.relationshipNote != null
                        ? '${person.fullName} (${person.relationshipNote})'
                        : person.fullName,
                    style: context.texts.titleMedium,
                  ),
                  const SizedBox(height: GuardianSpacing.xs),
                  Text(person.phone, style: context.texts.bodyMedium),
                  const SizedBox(height: GuardianSpacing.xs),
                  // The window is always shown, and prominently — nominations always
                  // expire (BR-GRD-005).
                  Text(
                    context.l10n.pickupPersonsValidRange(
                          _format(person.validFrom),
                          _format(person.validUntil),
                        ) +
                        (expired ? context.l10n.pickupPersonsExpiredSuffix : ''),
                    style: context.texts.bodyMedium?.copyWith(
                      color: expired ? context.status.warning : context.colors.onSurfaceVariant,
                      fontWeight: expired ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onRevoke, child: Text(context.l10n.pickupPersonsRevokeButton)),
          ],
        ),
      ),
    );
  }

  static String _format(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _AddForm extends StatelessWidget {
  const _AddForm({
    required this.state,
    required this.onFullNameChanged,
    required this.onPhoneChanged,
    required this.onRelationshipChanged,
    required this.onValidityChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  final PickupPersonsState state;
  final void Function(String) onFullNameChanged;
  final void Function(String) onPhoneChanged;
  final void Function(String) onRelationshipChanged;
  final void Function(DateTime from, DateTime until) onValidityChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GuardianSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.pickupPersonsNewPersonTitle, style: context.texts.titleMedium),
            const SizedBox(height: GuardianSpacing.md),
            TextFormField(
              key: const ValueKey('pickup_full_name'),
              initialValue: state.fullName,
              onChanged: onFullNameChanged,
              decoration: InputDecoration(labelText: context.l10n.pickupPersonsFullNameLabel),
            ),
            const SizedBox(height: GuardianSpacing.md),
            TextFormField(
              key: const ValueKey('pickup_phone'),
              initialValue: state.phone,
              keyboardType: TextInputType.phone,
              onChanged: onPhoneChanged,
              decoration: InputDecoration(labelText: context.l10n.pickupPersonsPhoneLabel),
            ),
            const SizedBox(height: GuardianSpacing.md),
            TextFormField(
              key: const ValueKey('pickup_relationship'),
              initialValue: state.relationshipNote,
              onChanged: onRelationshipChanged,
              decoration: InputDecoration(
                labelText: context.l10n.pickupPersonsRelationshipLabel,
                hintText: context.l10n.pickupPersonsRelationshipHint,
              ),
            ),
            const SizedBox(height: GuardianSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 365)),
                  initialDateRange: (state.validFrom != null && state.validUntil != null)
                      ? DateTimeRange(start: state.validFrom!, end: state.validUntil!)
                      : null,
                );
                if (range != null) onValidityChanged(range.start, range.end);
              },
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                (state.validFrom != null && state.validUntil != null)
                    ? context.l10n.pickupPersonsValidRange(
                        _format(state.validFrom!),
                        _format(state.validUntil!),
                      )
                    : context.l10n.pickupPersonsValidityChoose,
              ),
            ),
            const SizedBox(height: GuardianSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: Text(context.l10n.cancelButton),
                  ),
                ),
                const SizedBox(width: GuardianSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: state.isSubmittable ? onSubmit : null,
                    child: state.isSubmitting
                        ? const SizedBox(
                            height: AppSizeConstants.inlineSpinnerSize,
                            width: AppSizeConstants.inlineSpinnerSize,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.pickupPersonsNominateButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _format(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.failure});

  final Failure<void> failure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = switch (failure.code) {
      ErrorCode.guardianNotAuthorisedToNominate => l10n.pickupPersonsErrorNotAuthorised,
      ErrorCode.pickupPersonOutsideValidity => l10n.pickupPersonsErrorOutsideValidity,
      ErrorCode.dependencyUnavailable => l10n.errorDependencyUnavailable,
      _ => l10n.errorGenericTryAgain,
    };
    return Container(
      padding: const EdgeInsets.all(GuardianSpacing.md),
      decoration: BoxDecoration(
        color: context.status.warningSurface,
        borderRadius: BorderRadius.circular(GuardianRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.status.warning),
          const SizedBox(width: GuardianSpacing.sm),
          Expanded(child: Text(text, style: context.texts.bodyMedium)),
        ],
      ),
    );
  }
}

class _NoChildren extends StatelessWidget {
  const _NoChildren();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GuardianSpacing.xl),
        child: Text(
          context.l10n.pickupPersonsNoChildrenLinked,
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium,
        ),
      ),
    );
  }
}
