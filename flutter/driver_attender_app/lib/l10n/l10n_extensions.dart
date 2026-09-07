import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Call-shape mandated by CODING_STANDARDS_FLUTTER.md §Localisation:
/// `Text(context.l10n.studentBoardedAt(student.name, time))`, never raw string
/// interpolation. ADR-0013 delivers the strings from a bundled ARB instead of the
/// backend-driven design that section otherwise describes, but the call shape is unchanged
/// so call sites do not need to change again when `CFG-006` lands.
///
/// `l10n.yaml` sets `nullable-getter: false`, so [AppLocalizations.of] already returns a
/// non-null instance — resolvable because [AppLocalizations.delegate] is always in
/// `MaterialApp.localizationsDelegates` (wired in `main.dart`).
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
