/// Design tokens for the driver and attendant app.
///
/// Sizes only. Every color — the `ColorScheme`, the status palette, and the pending-sync
/// purple that used to live here — comes from the shared `guardian_theme` package, so this
/// app renders exactly the same colors as guardian-parent-app and guardian-admin-web.
/// Widgets read them through [GuardianStatusTheme.status] or `Theme.of(context).colorScheme`.
///
/// Before this change this file built its own `ColorScheme.fromSeed(..., contrastLevel:
/// 0.5)` with a deliberate contrast boost for a moving vehicle in glare. Sharing the exact
/// canonical scheme drops that extra boost — it still meets DESIGN_SYSTEM.md/
/// ACCESSIBILITY.md's AA figures, but re-check legibility in bright-light conditions before
/// shipping this change (see docs/05-ui/DRIVER_ATTENDANT_APP.md).
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

class DriverSpacing {
  const DriverSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Minimum touch target in this app.
///
/// Larger than the parent app's 48 and than the platform minimum, because a mis-tap here
/// records the wrong child as boarded.
const double kDriverTouchTarget = 64;

/// The SOS control is larger again, and never shares an edge with another control.
const double kSosTouchTarget = 88;

ThemeData buildDriverTheme(Brightness brightness) {
  final scheme = brightness == Brightness.dark
      ? guardianDarkColorScheme
      : guardianLightColorScheme;
  final status = GuardianStatusColors.of(brightness);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: <ThemeExtension<dynamic>>[status],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18),
      bodyMedium: TextStyle(fontSize: 18),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kDriverTouchTarget, kDriverTouchTarget),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: DriverSpacing.md,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DriverSpacing.md,
        vertical: DriverSpacing.sm,
      ),
    ),
  );
}
