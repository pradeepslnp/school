import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';

/// The seven-day codes the API stores, in calendar order (BR-TRIP-011).
///
/// Order matters: it is both the order the chips are drawn in and the order the value is sent,
/// so two routes running the same days produce the same string and read the same on screen.
const List<String> kOperatingDayCodes = <String>[
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

/// The five-day school week — what a route runs unless someone says otherwise.
const String kDefaultOperatingDays = 'MON,TUE,WED,THU,FRI';

/// Picks which days of the week a route runs.
///
/// This field decides whether a bus runs at all: MOD-08 generates a trip only for a day listed
/// here (BR-TRIP-011), so an unticked Tuesday is a Tuesday with no bus and no error message
/// anywhere. That is why it is a row of visible chips rather than a dropdown or a text field —
/// the whole week is on screen at once, and what is *not* selected is as legible as what is.
///
/// Emits the API's own comma-separated string rather than a set, because that is exactly what
/// the server stores. Translating between two shapes at the boundary is one more place for them
/// to disagree.
class OperatingDaysField extends StatelessWidget {
  const OperatingDaysField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// Comma-separated day codes, e.g. `MON,TUE,WED,THU,FRI`.
  final String value;

  final ValueChanged<String> onChanged;
  final bool enabled;

  Set<String> get _selected => value
      .split(',')
      .map((code) => code.trim().toUpperCase())
      .where((code) => code.isNotEmpty)
      .toSet();

  static String _encode(Set<String> selected) =>
      kOperatingDayCodes.where(selected.contains).join(',');

  void _toggle(String code) {
    final next = Set<String>.from(_selected);
    if (!next.remove(code)) next.add(code);
    onChanged(_encode(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.routeOperatingDaysLabel,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: AdminSpacing.xs),
        Wrap(
          spacing: AdminSpacing.xs,
          runSpacing: AdminSpacing.xs,
          children: [
            for (final code in kOperatingDayCodes)
              FilterChip(
                key: Key('route_operating_day_$code'),
                label: Text(_dayLabel(context, code)),
                selected: selected.contains(code),
                onSelected: enabled ? (_) => _toggle(code) : null,
              ),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        Row(
          children: [
            TextButton(
              key: const Key('route_operating_days_weekdays'),
              onPressed: enabled ? () => onChanged(kDefaultOperatingDays) : null,
              child: Text(context.l10n.routeOperatingDaysWeekdaysPreset),
            ),
            TextButton(
              key: const Key('route_operating_days_all'),
              onPressed: enabled ? () => onChanged(kOperatingDayCodes.join(',')) : null,
              child: Text(context.l10n.routeOperatingDaysAllPreset),
            ),
          ],
        ),
        Text(
          // Stated as a consequence, not as a rule: an operator reading "trips are generated
          // only for these days" understands what unticking Saturday does without being told
          // what BR-TRIP-011 is.
          selected.isEmpty
              ? context.l10n.routeOperatingDaysNoneSelected
              : context.l10n.routeOperatingDaysHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected.isEmpty
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static String _dayLabel(BuildContext context, String code) {
    return switch (code) {
      'MON' => context.l10n.routeDayMonShort,
      'TUE' => context.l10n.routeDayTueShort,
      'WED' => context.l10n.routeDayWedShort,
      'THU' => context.l10n.routeDayThuShort,
      'FRI' => context.l10n.routeDayFriShort,
      'SAT' => context.l10n.routeDaySatShort,
      'SUN' => context.l10n.routeDaySunShort,
      // Unreachable for the seven codes above; shown rather than hidden if the server ever
      // sends something new, because a silently dropped day is how a bus stops running.
      _ => code,
    };
  }
}
