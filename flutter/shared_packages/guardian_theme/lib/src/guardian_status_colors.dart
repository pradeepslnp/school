import 'package:flutter/material.dart';

import 'guardian_colors.dart';

/// The five status colors, already resolved for the active theme.
///
/// Exists so a component asks for *meaning* — "this is a warning" — rather than for a
/// brightness and a color. Every `isDark ? x : y` removed from a widget is one fewer place
/// for the dark theme to be wrong.
///
/// Each color is paired with a low-contrast surface-tint color for chip and banner fills,
/// so a component never invents a background by applying an opacity to a foreground color
/// and hoping the result still meets AA.
@immutable
class GuardianStatusColors extends ThemeExtension<GuardianStatusColors> {
  const GuardianStatusColors({
    required this.safe,
    required this.safeSurface,
    required this.info,
    required this.infoSurface,
    required this.warning,
    required this.warningSurface,
    required this.critical,
    required this.criticalSurface,
    required this.neutral,
    required this.neutralSurface,
    required this.pendingSync,
    required this.pendingSyncSurface,
  });

  /// Boarded, arrived, handed over.
  final Color safe;
  final Color safeSurface;

  /// In progress, scheduled.
  final Color info;
  final Color infoSurface;

  /// Delayed, expiring, no-show.
  final Color warning;
  final Color warningSurface;

  /// Unaccounted child, SOS, override — genuine safety events only.
  final Color critical;
  final Color criticalSurface;

  /// Not started, absent, unknown.
  final Color neutral;
  final Color neutralSurface;

  /// Recorded locally, not yet synced (ADR-0008).
  final Color pendingSync;
  final Color pendingSyncSurface;

  static const _light = GuardianStatusColors(
    safe: GuardianColors.safe,
    safeSurface: Color(0xFFE7F3EC),
    info: GuardianColors.info,
    infoSurface: Color(0xFFE6EFF9),
    warning: GuardianColors.warning,
    warningSurface: Color(0xFFFBF0DE),
    critical: GuardianColors.critical,
    criticalSurface: Color(0xFFFCE8E6),
    neutral: GuardianColors.neutral,
    neutralSurface: Color(0xFFEEF0F3),
    pendingSync: GuardianColors.pendingSync,
    pendingSyncSurface: Color(0xFFEFE9F8),
  );

  static const _dark = GuardianStatusColors(
    safe: GuardianColors.safeDark,
    safeSurface: Color(0xFF16291F),
    info: GuardianColors.infoDark,
    infoSurface: Color(0xFF16222E),
    warning: GuardianColors.warningDark,
    warningSurface: Color(0xFF2B2213),
    critical: GuardianColors.criticalDark,
    criticalSurface: Color(0xFF31191A),
    neutral: GuardianColors.neutralDark,
    neutralSurface: Color(0xFF23272D),
    pendingSync: GuardianColors.pendingSyncDark,
    pendingSyncSurface: Color(0xFF241E33),
  );

  static GuardianStatusColors of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  @override
  GuardianStatusColors copyWith({
    Color? safe,
    Color? safeSurface,
    Color? info,
    Color? infoSurface,
    Color? warning,
    Color? warningSurface,
    Color? critical,
    Color? criticalSurface,
    Color? neutral,
    Color? neutralSurface,
    Color? pendingSync,
    Color? pendingSyncSurface,
  }) {
    return GuardianStatusColors(
      safe: safe ?? this.safe,
      safeSurface: safeSurface ?? this.safeSurface,
      info: info ?? this.info,
      infoSurface: infoSurface ?? this.infoSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      critical: critical ?? this.critical,
      criticalSurface: criticalSurface ?? this.criticalSurface,
      neutral: neutral ?? this.neutral,
      neutralSurface: neutralSurface ?? this.neutralSurface,
      pendingSync: pendingSync ?? this.pendingSync,
      pendingSyncSurface: pendingSyncSurface ?? this.pendingSyncSurface,
    );
  }

  @override
  GuardianStatusColors lerp(
    ThemeExtension<GuardianStatusColors>? other,
    double t,
  ) {
    if (other is! GuardianStatusColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;

    return GuardianStatusColors(
      safe: mix(safe, other.safe),
      safeSurface: mix(safeSurface, other.safeSurface),
      info: mix(info, other.info),
      infoSurface: mix(infoSurface, other.infoSurface),
      warning: mix(warning, other.warning),
      warningSurface: mix(warningSurface, other.warningSurface),
      critical: mix(critical, other.critical),
      criticalSurface: mix(criticalSurface, other.criticalSurface),
      neutral: mix(neutral, other.neutral),
      neutralSurface: mix(neutralSurface, other.neutralSurface),
      pendingSync: mix(pendingSync, other.pendingSync),
      pendingSyncSurface: mix(pendingSyncSurface, other.pendingSyncSurface),
    );
  }
}
