import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';

/// The greeting, and the one place the screen states which clock it is using.
///
/// Every time on this screen is school-local (BR-CFG-006). Labelling the zone once here,
/// rather than suffixing every timestamp, keeps the cards scannable while still telling a
/// parent in another country which clock they are reading — the requirement is that the
/// zone is stated, not that it is repeated.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.guardianName,
    required this.schoolNow,
  });

  final String guardianName;

  /// The current time at the school, which is what decides the greeting.
  ///
  /// A parent in London opening the app at 22:00 their time is looking at a school where it
  /// is morning; greeting them with "Good evening" above a morning bus would be incoherent.
  ///
  /// Null until the school's calendar configuration has loaded. The greeting then falls
  /// back to the device clock and the zone line is omitted — a pleasantry may be
  /// approximate, but a *stated* timezone may not, and printing an unverified one would be
  /// the precise failure BR-CFG-006 guards against.
  final SchoolTime? schoolNow;

  @override
  Widget build(BuildContext context) {
    final now = schoolNow;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GuardianSpacing.md,
        GuardianSpacing.sm,
        GuardianSpacing.md,
        GuardianSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.dashboardGreeting(
              _greeting(context, (now?.value ?? DateTime.now()).hour),
              guardianName,
            ),
            style: context.texts.headlineSmall,
          ),
          if (now != null) ...[
            const SizedBox(height: GuardianSpacing.xs),
            Semantics(
              label: context.l10n.schoolTimeZoneSemanticLabel(now.timezoneId),
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: AppSizeConstants.iconXs,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: GuardianSpacing.xs),
                  Flexible(
                    child: Text(
                      context.l10n.schoolTimeLabel(now.timezoneId),
                      style: context.texts.labelMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _greeting(BuildContext context, int hourOfDay) {
    final l10n = context.l10n;
    if (hourOfDay < 12) return l10n.greetingMorning;
    if (hourOfDay < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }
}
