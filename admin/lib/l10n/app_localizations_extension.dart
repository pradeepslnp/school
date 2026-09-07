import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// The call-shape `CODING_STANDARDS_FLUTTER.md`'s Localisation section documents:
/// `Text(context.l10n.studentBoardedAt(student.name, time))`, never raw string
/// interpolation. Delivery is client-bundled for this interim pass (ADR-0013) rather than
/// the backend-driven `CFG-006` design ADR-0007 targets, but the call site is written to the
/// same shape so migrating later does not touch a single widget.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
