import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../utils/utils.dart';
import '../bloc/absence_bloc.dart';
import '../repository/models/absence.dart';

/// P-06 — declare an absence.
///
/// Renders state it is given and emits events; it decides nothing itself, including
/// whether the form is submittable — that is [AbsenceState.isSubmittable]
/// (ENGINEERING_PRINCIPLES.md §8).
class AbsenceScreen extends StatelessWidget {
  const AbsenceScreen({
    super.key,
    required this.state,
    required this.onChildSelected,
    required this.onWhenChanged,
    required this.onDateRangeChanged,
    required this.onJourneyChanged,
    required this.onReasonChanged,
    required this.onSubmit,
    required this.onCancelAbsence,
  });

  final AbsenceState state;
  final void Function(ChildOption) onChildSelected;
  final void Function(AbsenceWhen) onWhenChanged;
  final void Function(DateTime from, DateTime to) onDateRangeChanged;
  final void Function(AbsenceDirection) onJourneyChanged;
  final void Function(String) onReasonChanged;
  final VoidCallback onSubmit;
  final void Function(String absenceId) onCancelAbsence;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Declare absence')),
      body: SafeArea(
        child: state.children.isEmpty
            ? const _NoChildren()
            : ReadableWidth(
                child: ListView(
                  padding: const EdgeInsets.all(GuardianSpacing.md),
                  children: [
                    if (state.children.length > 1) ...[
                      Text('Which child?', style: context.texts.titleMedium),
                      const SizedBox(height: GuardianSpacing.sm),
                      _ChoiceChipRow<ChildOption>(
                        options: [
                          for (final child in state.children) (child, child.displayName),
                        ],
                        selected: state.selectedChild,
                        onChanged: onChildSelected,
                      ),
                      const SizedBox(height: GuardianSpacing.lg),
                    ],
                    Text('When?', style: context.texts.titleMedium),
                    const SizedBox(height: GuardianSpacing.sm),
                    _ChoiceChipRow<AbsenceWhen>(
                      options: const [
                        (AbsenceWhen.today, 'Today'),
                        (AbsenceWhen.tomorrow, 'Tomorrow'),
                        (AbsenceWhen.dateRange, 'Date range'),
                      ],
                      selected: state.when,
                      onChanged: onWhenChanged,
                    ),
                    if (state.when == AbsenceWhen.dateRange) ...[
                      const SizedBox(height: GuardianSpacing.sm),
                      _DateRangePicker(
                        from: state.rangeFrom,
                        to: state.rangeTo,
                        onChanged: onDateRangeChanged,
                      ),
                    ],
                    const SizedBox(height: GuardianSpacing.lg),
                    Text('Which journey?', style: context.texts.titleMedium),
                    const SizedBox(height: GuardianSpacing.sm),
                    _ChoiceChipRow<AbsenceDirection>(
                      options: const [
                        (AbsenceDirection.both, 'Both'),
                        (AbsenceDirection.morningOnly, 'Morning'),
                        (AbsenceDirection.afternoonOnly, 'Afternoon'),
                      ],
                      selected: state.direction,
                      onChanged: onJourneyChanged,
                    ),
                    const SizedBox(height: GuardianSpacing.lg),
                    Text('Reason (optional)', style: context.texts.titleMedium),
                    const SizedBox(height: GuardianSpacing.sm),
                    TextFormField(
                      // Remounts — and so re-reads `initialValue` — exactly when a
                      // declaration is confirmed or an absence is cancelled, which is when
                      // the bloc resets `reason`. An uncontrolled field otherwise never
                      // reflects a state change made outside it, the same choice
                      // `PhoneEntryForm` makes for the login form.
                      key: ValueKey(
                        'absence_reason_${state.selectedChild?.studentId}_${state.upcoming.length}',
                      ),
                      initialValue: state.reason,
                      onChanged: onReasonChanged,
                      decoration: const InputDecoration(
                        hintText: 'Not required',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (state.submitFailure != null) ...[
                      const SizedBox(height: GuardianSpacing.md),
                      _ErrorBanner(failure: state.submitFailure!),
                    ],
                    if (state.confirmation != null) ...[
                      const SizedBox(height: GuardianSpacing.md),
                      _ConfirmationBanner(text: state.confirmation!),
                    ],
                    const SizedBox(height: GuardianSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state.isSubmittable ? onSubmit : null,
                        child: state.isSubmitting
                            ? const SizedBox(
                                height: AppSizeConstants.inlineSpinnerSize,
                                width: AppSizeConstants.inlineSpinnerSize,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirm'),
                      ),
                    ),
                    const SizedBox(height: GuardianSpacing.xl),
                    Text('Upcoming absences', style: context.texts.titleMedium),
                    const SizedBox(height: GuardianSpacing.sm),
                    if (state.isLoadingList && state.upcoming.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: GuardianSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    // A failed load is never presented as "nothing declared" — that reads as
                    // reassuring when it means the opposite: the app does not actually know.
                    else if (state.listFailure != null && state.upcoming.isEmpty)
                      _ErrorBanner(failure: state.listFailure!)
                    else if (state.upcoming.isEmpty)
                      Text(
                        'No absences declared for this child.',
                        style: context.texts.bodyMedium
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < state.upcoming.length; i++) ...[
                              if (i > 0) const Divider(height: 1),
                              _UpcomingAbsenceTile(
                                absence: state.upcoming[i],
                                onCancel: () => onCancelAbsence(state.upcoming[i].id),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// A row of mutually-exclusive choices, one tap each, no radio glyph to parse.
///
/// Replaces a dropdown-plus-radio-list pattern with the row of buttons
/// docs/05-ui/PARENT_APP.md's P-06 mockup shows: every option is visible and reachable in
/// one tap, which matters more here than on a form with room to spare — this one is filled
/// out one-handed, often while already walking to the gate.
class _ChoiceChipRow<T> extends StatelessWidget {
  const _ChoiceChipRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T value, String label)> options;
  final T? selected;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: GuardianSpacing.sm),
          Expanded(
            child: _ChoiceChip(
              label: options[i].$2,
              selected: options[i].$1 == selected,
              onTap: () => onChanged(options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected reads as a filled button, unselected as outlined — the same visual
    // vocabulary the rest of the app already uses for "chosen" versus "choosable"
    // (e.g. the submit button beside the cancel button on this same screen), rather than
    // inventing a third convention just for this row.
    return selected
        ? FilledButton(onPressed: onTap, child: Text(label, textAlign: TextAlign.center))
        : OutlinedButton(onPressed: onTap, child: Text(label, textAlign: TextAlign.center));
  }
}

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({required this.from, required this.to, required this.onChanged});

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime from, DateTime to) onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 365)),
          initialDateRange: (from != null && to != null) ? DateTimeRange(start: from!, end: to!) : null,
        );
        if (range != null) onChanged(range.start, range.end);
      },
      icon: const Icon(Icons.date_range_outlined),
      label: Text(
        (from != null && to != null)
            ? '${_format(from!)} – ${_format(to!)}'
            : 'Choose dates',
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
    final text = switch (failure.code) {
      ErrorCode.absenceTripAlreadyStarted =>
        'This trip has already started, so this absence cannot be declared. '
            'Contact the school office instead.',
      ErrorCode.dependencyUnavailable =>
        'Your device cannot reach the school right now. Check your connection and try again.',
      _ => 'Something went wrong. Please try again.',
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

class _ConfirmationBanner extends StatelessWidget {
  const _ConfirmationBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GuardianSpacing.md),
      decoration: BoxDecoration(
        color: context.status.safeSurface,
        borderRadius: BorderRadius.circular(GuardianRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: context.status.safe),
          const SizedBox(width: GuardianSpacing.sm),
          Expanded(child: Text(text, style: context.texts.bodyMedium)),
        ],
      ),
    );
  }
}

class _UpcomingAbsenceTile extends StatelessWidget {
  const _UpcomingAbsenceTile({required this.absence, required this.onCancel});

  final Absence absence;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final journey = switch (absence.direction) {
      AbsenceDirection.both => 'Both journeys',
      AbsenceDirection.morningOnly => 'Morning only',
      AbsenceDirection.afternoonOnly => 'Afternoon only',
    };
    final sameDay = absence.fromDate.year == absence.toDate.year &&
        absence.fromDate.month == absence.toDate.month &&
        absence.fromDate.day == absence.toDate.day;
    final when = sameDay
        ? _format(absence.fromDate)
        : '${_format(absence.fromDate)} – ${_format(absence.toDate)}';

    return ListTile(
      title: Text(when),
      subtitle: Text(
        [journey, if (absence.reason != null) absence.reason!].join(' · '),
      ),
      trailing: TextButton(onPressed: onCancel, child: const Text('Cancel')),
    );
  }

  static String _format(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _NoChildren extends StatelessWidget {
  const _NoChildren();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GuardianSpacing.xl),
        child: Text(
          'Your school links your children to your account before you can declare an '
          'absence.',
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium,
        ),
      ),
    );
  }
}
