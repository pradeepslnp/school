import 'package:flutter/material.dart';
import 'package:guardian_theme/guardian_theme.dart';

// Design tokens for the parent app.
//
// Mirrors docs/05-ui/DESIGN_SYSTEM.md. Components reference these semantic names, never
// raw color values — a status color that appears literally in a widget is a color that
// will drift from the system.
//
// Colors (brand palette, status colors, and the light/dark `ColorScheme`s) live in the
// `guardian_theme` package and are shared with guardian-driver-app and guardian-admin-web —
// see that package's README. `GuardianColors` and `GuardianStatusColors` are re-exported
// below so existing imports of this file keep working unchanged.
//
// Lives in the app rather than in `guardian_core` because `guardian_core` must stay free
// of Flutter (ADR-0003).

/// Re-exports the shared color theme (`GuardianColors`, `GuardianStatusColors`,
/// `guardianLightColorScheme`, `guardianDarkColorScheme`) so existing imports of this file
/// keep resolving those names unchanged.
export 'package:guardian_theme/guardian_theme.dart';

/// Reads the app's tokens off a [BuildContext].
extension GuardianTheme on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  /// The status palette for the active theme.
  ///
  /// Falls back to the light set rather than throwing: a widget pumped in a bare
  /// `MaterialApp` in a test should render, not crash.
  GuardianStatusColors get status =>
      Theme.of(this).extension<GuardianStatusColors>() ??
      GuardianStatusColors.of(Theme.of(this).brightness);
}

class GuardianSpacing {
  const GuardianSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii, from DESIGN_SYSTEM.md.
class GuardianRadius {
  const GuardianRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
}

/// Minimum touch target for the parent app.
///
/// The driver app uses 64 (and 88 for SOS) because it is operated in a moving vehicle —
/// see docs/05-ui/DRIVER_ATTENDANT_APP.md.
const double kMinimumTouchTarget = 48;

/// The type scale from DESIGN_SYSTEM.md.
///
/// Sizes only — color is applied per theme in [buildParentTheme], and heights are set here
/// because the 1.5 line-height minimum in ACCESSIBILITY.md is a property of the scale, not
/// of the theme it is used in.
const _textTheme = TextTheme(
  displayLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  ),
  headlineSmall: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  ),
  titleLarge: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  ),
  // 16px minimum body text: this app is read in 10-20 second glances, one-handed,
  // often in poor light (docs/05-ui/PARENT_APP.md).
  bodyLarge: TextStyle(fontSize: 16, height: 1.5),
  bodyMedium: TextStyle(fontSize: 16, height: 1.5),
  // Supporting metadata only. Anything a parent reads while moving stays at 16.
  bodySmall: TextStyle(fontSize: 14, height: 1.5),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
  labelMedium: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  ),
  labelSmall: TextStyle(fontSize: 12, height: 1.4),
);

/// Builds the parent app theme for a brightness.
///
/// Both themes are built from the same component definitions, so a control cannot pick up
/// a rounded corner or a touch-target floor in one theme and lose it in the other.
ThemeData buildParentTheme(Brightness brightness) {
  final scheme = brightness == Brightness.dark
      ? guardianDarkColorScheme
      : guardianLightColorScheme;
  final status = GuardianStatusColors.of(brightness);

  final minimumTarget = WidgetStateProperty.all(
    const Size(kMinimumTouchTarget, kMinimumTouchTarget),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>[status],
    textTheme: _textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GuardianRadius.lg),
        // Elevation alone is unreliable in dark mode and invisible to anyone using a
        // high-contrast display setting, so a card is bounded by a line as well
        // (DESIGN_SYSTEM.md: elevation is never the sole indicator).
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: GuardianSpacing.md,
        vertical: GuardianSpacing.sm,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kMinimumTouchTarget, kMinimumTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.md),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(kMinimumTouchTarget, kMinimumTouchTarget),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.md),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(kMinimumTouchTarget, kMinimumTouchTarget),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(minimumSize: minimumTarget),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: GuardianSpacing.sm,
      iconColor: scheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GuardianRadius.md),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GuardianRadius.md),
        borderSide: BorderSide(color: scheme.outline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GuardianRadius.md),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
