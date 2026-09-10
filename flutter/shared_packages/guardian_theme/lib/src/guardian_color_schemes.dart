import 'package:flutter/material.dart';

import 'guardian_colors.dart';

/// The Guardian brand palette backing [guardianLightColorScheme] and
/// [guardianDarkColorScheme].
///
/// Private to this package on purpose. Screens read [ColorScheme] and
/// [GuardianStatusColors]; nothing outside this package should know that "the brand is
/// navy", because that is exactly the knowledge that leaks into a widget and survives a
/// rebrand.
abstract final class _Brand {
  /// Deep navy. Carries white text at every size.
  static const navy = Color(0xFF0B2443);
  static const navyTint = Color(0xFFF5F8FF);

  /// The action blue. Lighter than [navy] so a button reads as a button, not as chrome.
  static const blue = Color(0xFF244DA7);
  static const blueTint = Color(0xFFE4ECFF);

  /// The dark-theme counterparts. A navy primary is unreadable against a dark surface, so
  /// dark mode uses the light end of the same hue rather than the same ink.
  static const navyLight = Color(0xFFAEC5E7);
  static const blueLight = Color(0xFF5B9BD8);

  static const sand = Color(0xFFF7F3E6);
}

/// Light color roles. One set for all three Guardian clients.
///
/// Written out rather than seeded from a brand color. `ColorScheme.fromSeed` produces a
/// harmonious palette but not a *specified* one, and DESIGN_SYSTEM.md commits to exact
/// values that ACCESSIBILITY.md then holds to a contrast ratio — a generated approximation
/// of those values cannot be verified against the table it is meant to implement.
const guardianLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _Brand.navy,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: _Brand.navyTint,
  onPrimaryContainer: Color(0xFF14181F),
  secondary: _Brand.blue,
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: _Brand.blueTint,
  onSecondaryContainer: Color(0xFF14181F),
  tertiary: GuardianColors.safe,
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: _Brand.sand,
  onTertiaryContainer: Color(0xFF14181F),
  // The doc's `statusCritical`, not a brighter red: `error` fills buttons and snackbar
  // that carry white text, and the brighter reds in the brand sheet do not reach 4.5:1
  // underneath it.
  error: GuardianColors.critical,
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFCE7E7),
  onErrorContainer: Color(0xFF5F1512),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF14181F),
  surfaceDim: Color(0xFFE8EAEE),
  surfaceBright: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFAFBFC),
  surfaceContainer: Color(0xFFF6F7F9),
  surfaceContainerHigh: Color(0xFFF0F2F5),
  surfaceContainerHighest: Color(0xFFE9ECF0),
  onSurfaceVariant: Color(0xFF5A6472),
  // `outline` draws control borders and focus rings, which ACCESSIBILITY.md holds to 3:1;
  // the pale divider color lives in `outlineVariant`, where nothing depends on it for
  // legibility.
  outline: Color(0xFF6B7688),
  outlineVariant: Color(0xFFD1D9EA),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2A2F36),
  onInverseSurface: Color(0xFFF1F3F6),
  inversePrimary: _Brand.navyLight,
);

/// Dark color roles.
///
/// Not a mechanical inversion. The navy that carries the brand in light mode disappears
/// against a dark surface, so the primary moves to the light end of the same hue while the
/// status colors move to their `*Dark` pairs — both from the DESIGN_SYSTEM.md table, both
/// AA against the dark surfaces below.
const guardianDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _Brand.blueLight,
  onPrimary: Color(0xFF0A1017),
  primaryContainer: Color(0xFF1B3352),
  onPrimaryContainer: Color(0xFFD6E4F5),
  secondary: _Brand.navyLight,
  onSecondary: Color(0xFF0A1017),
  secondaryContainer: Color(0xFF23364F),
  onSecondaryContainer: Color(0xFFDCE6F4),
  tertiary: GuardianColors.safeDark,
  onTertiary: Color(0xFF06140D),
  tertiaryContainer: Color(0xFF1B3D2C),
  onTertiaryContainer: Color(0xFFCFEBDC),
  error: GuardianColors.criticalDark,
  onError: Color(0xFF3B0906),
  errorContainer: Color(0xFF6B1C16),
  onErrorContainer: Color(0xFFFBDAD7),
  surface: Color(0xFF121417),
  onSurface: Color(0xFFEDEFF2),
  surfaceDim: Color(0xFF121417),
  surfaceBright: Color(0xFF32363C),
  surfaceContainerLowest: Color(0xFF0D0F12),
  surfaceContainerLow: Color(0xFF181B1F),
  surfaceContainer: Color(0xFF1C1F24),
  surfaceContainerHigh: Color(0xFF23272D),
  surfaceContainerHighest: Color(0xFF2E3238),
  onSurfaceVariant: Color(0xFFA2ABB8),
  outline: Color(0xFF8A94A3),
  outlineVariant: Color(0xFF2C313A),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFEDEFF2),
  onInverseSurface: Color(0xFF1C1F24),
  inversePrimary: _Brand.navy,
);
