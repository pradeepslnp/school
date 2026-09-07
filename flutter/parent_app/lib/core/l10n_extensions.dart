import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

/// The call shape documented in CODING_STANDARDS_FLUTTER.md's Localisation section:
/// `Text(context.l10n.studentBoardedAt(student.name, time))`, never a raw string
/// interpolation (BR-CFG-005).
///
/// Resolves to the generated [AppLocalizations] for this pass (ADR-0013 — client-bundled
/// ARB, not the backend-driven `CFG-006` design). A future migration to that design should
/// not need to change any call site: only what this getter resolves to.
extension AppLocalizationsX on BuildContext {
  // l10n.yaml sets `nullable-getter: false`, so the generated `of()` already throws — with a
  // clear message naming the missing delegate — rather than returning null when this is
  // called outside a MaterialApp/WidgetsApp; no `!` needed.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
