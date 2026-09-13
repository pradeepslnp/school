/// Design tokens for the administration console.
///
/// Denser than the mobile apps: this is a desk tool used for sustained periods on a large
/// screen, where the mobile apps' generous targets and larger body text would waste space
/// that operators need for data (docs/05-ui/ADMIN_WEB.md).
///
/// The **status palette and the action colors** still come from the shared
/// `guardian_theme` package, so this console renders exactly the same safety colors as
/// guardian-parent-app and guardian-driver-app. Widgets read them through
/// [GuardianStatusTheme.status] or `Theme.of(context).colorScheme`.
///
/// What is console-only is the **livery** ([AdminLivery]) — the school-bus yellow chrome
/// and the warm neutral work surface. It lives here rather than in `guardian_theme`
/// deliberately: that package is shared by all three clients, and a color added there
/// would repaint the parent and driver apps too.
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

/// Reads the console livery off a [BuildContext].
extension AdminLiveryTheme on BuildContext {
  /// The livery colors for the active theme, falling back rather than throwing for the
  /// same reason [GuardianStatusTheme.status] does.
  AdminLivery get livery =>
      Theme.of(this).extension<AdminLivery>() ??
      AdminLivery.of(Theme.of(this).brightness);
}

/// The console's own chrome: school-bus yellow navigation on a warm neutral work surface.
///
/// ## Why yellow is never a status and never carries text
///
/// School-bus yellow is the most recognisable color in child transport — it was chosen for
/// real buses because drivers catch it in peripheral vision faster than any other hue. That
/// makes it excellent for a navigation rail an operator glances at, and unusable for almost
/// everything else, for two independent reasons:
///
/// 1. **Contrast.** Yellow cannot reach 3:1 against white at any usable saturation, so
///    yellow text fails and white-on-yellow fails every contrast test, including at large
///    sizes. Black on yellow reaches ~19:1 — which is exactly why real buses carry black
///    lettering. Everything drawn on [rail] therefore uses [railInk] or [railMutedInk],
///    never white, and no button is ever filled yellow: primary actions stay on the shared
///    `colorScheme.primary` navy.
/// 2. **Semantics.** `GuardianColors.warning` already spends amber on *delayed, expiring,
///    no-show*. A yellow that also meant "brand" would weaken the one signal that has to
///    stay unambiguous, so yellow appears only as chrome — rail, wordmark, selected
///    destination — and never as the state of anything.
///
/// See `documentation/05-ui/DESIGN_SYSTEM.md` and `ACCESSIBILITY.md` §Contrast.
@immutable
class AdminLivery extends ThemeExtension<AdminLivery> {
  const AdminLivery({
    required this.rail,
    required this.railInk,
    required this.railMutedInk,
    required this.canvas,
    required this.panel,
    required this.panelSubtle,
    required this.border,
    required this.borderStrong,
    required this.placeholder,
  });

  /// The navigation rail. Identity and wayfinding only — never a state, never behind text
  /// that is not [railInk].
  final Color rail;

  /// Near-black ink for everything drawn on [rail], as a bus carries black lettering.
  final Color railInk;

  /// Secondary ink on [rail] — section headings, the signed-in operator's role.
  final Color railMutedInk;

  /// The work surface behind content panels. Warm rather than blue-grey, so the yellow
  /// rail reads as part of one palette instead of pasted onto a cool console.
  final Color canvas;

  /// Cards, tables, the header bar.
  final Color panel;

  /// Table headings, footers, and stat tiles — one step off [panel].
  final Color panelSubtle;

  /// Hairlines between rows.
  final Color border;

  /// Control outlines, which ACCESSIBILITY.md holds to 3:1.
  final Color borderStrong;

  /// Placeholder and hint text.
  final Color placeholder;

  static const _light = AdminLivery(
    rail: Color(0xFFFAD35E),
    railInk: Color(0xFF171310),
    railMutedInk: Color(0xFF5C4B12),
    canvas: Color(0xFFF6F4F0),
    panel: Color(0xFFFFFFFF),
    panelSubtle: Color(0xFFFAF8F4),
    border: Color(0xFFE4E0D8),
    borderStrong: Color(0xFFD8D3C8),
    placeholder: Color(0xFF8A8574),
  );

  /// Dark mode keeps the rail — the livery is the product's identity, not a light-mode
  /// decoration — and moves only the work surface, which is where the reading happens.
  static const _dark = AdminLivery(
    rail: Color(0xFFE8BE4A),
    railInk: Color(0xFF171310),
    railMutedInk: Color(0xFF54430E),
    canvas: Color(0xFF15181C),
    panel: Color(0xFF1C2026),
    panelSubtle: Color(0xFF232830),
    border: Color(0xFF2E343D),
    borderStrong: Color(0xFF444C57),
    placeholder: Color(0xFF8D96A3),
  );

  static AdminLivery of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  @override
  AdminLivery copyWith({
    Color? rail,
    Color? railInk,
    Color? railMutedInk,
    Color? canvas,
    Color? panel,
    Color? panelSubtle,
    Color? border,
    Color? borderStrong,
    Color? placeholder,
  }) {
    return AdminLivery(
      rail: rail ?? this.rail,
      railInk: railInk ?? this.railInk,
      railMutedInk: railMutedInk ?? this.railMutedInk,
      canvas: canvas ?? this.canvas,
      panel: panel ?? this.panel,
      panelSubtle: panelSubtle ?? this.panelSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      placeholder: placeholder ?? this.placeholder,
    );
  }

  @override
  AdminLivery lerp(covariant AdminLivery? other, double t) {
    if (other == null) return this;
    return AdminLivery(
      rail: Color.lerp(rail, other.rail, t)!,
      railInk: Color.lerp(railInk, other.railInk, t)!,
      railMutedInk: Color.lerp(railMutedInk, other.railMutedInk, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelSubtle: Color.lerp(panelSubtle, other.panelSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
    );
  }
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

/// The console's UI face. Bundled in `pubspec.yaml`, not fetched at runtime.
const String kAdminFontFamily = 'Barlow';

/// The display face, for screen titles and the operations counts.
///
/// Used through [TextStyle.fontFamily] on individual styles rather than as the theme's
/// family: it is deliberately not the reading face.
const String kAdminDisplayFontFamily = 'Archivo';

ThemeData buildAdminTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final livery = AdminLivery.of(brightness);

  // The shared scheme supplies every action and status color unchanged. Only the neutral
  // surfaces move, from the shared cool greys to the livery's warm ones, so the yellow rail
  // and the work surface read as one palette. `primary`, `secondary`, `error` and the
  // status extension are untouched — those are the cross-client safety contract.
  final scheme =
      (isDark ? guardianDarkColorScheme : guardianLightColorScheme).copyWith(
        surface: livery.panel,
        surfaceContainerLowest: livery.panel,
        surfaceContainerLow: livery.panelSubtle,
        surfaceContainer: livery.canvas,
        surfaceContainerHigh: livery.panelSubtle,
        outline: livery.borderStrong,
        outlineVariant: livery.border,
      );
  final status = GuardianStatusColors.of(brightness);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: <ThemeExtension<dynamic>>[status, livery],
    visualDensity: VisualDensity.compact,
    fontFamily: kAdminFontFamily,
    scaffoldBackgroundColor: livery.canvas,
    dividerColor: livery.border,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 14),
      bodyMedium: TextStyle(fontSize: 14),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      // Screen titles take the display face — wider, and it holds its shape at the sizes
      // the operations counts are set in.
      headlineSmall: TextStyle(
        fontFamily: kAdminDisplayFontFamily,
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kAdminTouchTarget * 2, kAdminTouchTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(kAdminTouchTarget * 2, kAdminTouchTarget),
        side: BorderSide(color: livery.borderStrong),
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    ),
    cardTheme: CardThemeData(
      color: livery.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: livery.border),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: livery.panel,
      hintStyle: TextStyle(color: livery.placeholder),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: livery.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: livery.borderStrong),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowHeight: 42,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 52,
      headingRowColor: WidgetStatePropertyAll(livery.panelSubtle),
      dividerThickness: 1,
    ),
  );
}
