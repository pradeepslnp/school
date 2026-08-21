/// Design tokens for the administration console.
///
/// Denser than the mobile apps: this is a desk tool used for sustained periods on a large
/// screen, where the mobile apps' generous targets and larger body text would waste space
/// that operators need for data (docs/05-ui/ADMIN_WEB.md).
///
/// Sizes only. Every color — the `ColorScheme` and the status palette — comes from the
/// shared `guardian_theme` package, so this console renders exactly the same colors as
/// guardian-parent-app and guardian-driver-app. Widgets read them through
/// [GuardianStatusTheme.status] or `Theme.of(context).colorScheme`.
library;

import 'package:flutter/material.dart';
import 'package:guardian_theme/guardian_theme.dart';

/// Reads the shared status palette off a [BuildContext].
extension GuardianStatusTheme on BuildContext {
  /// The status colors for the active theme.
  ///
  /// Falls back to the light set rather than throwing: a widget pumped in a bare
  /// `MaterialApp` in a test should render, not crash.
  GuardianStatusColors get status =>
      Theme.of(this).extension<GuardianStatusColors>() ??
      GuardianStatusColors.of(Theme.of(this).brightness);
}

class AdminSpacing {
  const AdminSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Minimum interactive size for this console: **40 × 40**
/// ([`ACCESSIBILITY.md`](../../../guardian-docs/05-ui/ACCESSIBILITY.md) §Touch targets).
///
/// Lower than the mobile apps' 48/64 because a mouse is precise — but 40 is the floor the
/// accessibility document sets for admin web, not a value to tune for density. This constant
/// read 36 until the sign-in screen was built, which would have failed the audit that
/// ADR-0003 names as its own reconsideration trigger.
///
/// Any control also reachable on a touch device must still meet 48.
const double kAdminTouchTarget = 40;

ThemeData buildAdminTheme(Brightness brightness) {
  final scheme = brightness == Brightness.dark
      ? guardianDarkColorScheme
      : guardianLightColorScheme;
  final status = GuardianStatusColors.of(brightness);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: <ThemeExtension<dynamic>>[status],
    visualDensity: VisualDensity.compact,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 14),
      bodyMedium: TextStyle(fontSize: 14),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kAdminTouchTarget * 2, kAdminTouchTarget),
      ),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowHeight: 40,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 44,
    ),
  );
}
