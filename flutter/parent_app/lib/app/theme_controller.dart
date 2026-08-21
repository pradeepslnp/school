import 'package:flutter/material.dart';

/// Holds the app's light/dark preference.
///
/// A [ValueNotifier] rather than a BLoC: there is no event to validate, no server to ask,
/// and no failure state — adding a bloc here would be ceremony around a single enum
/// (ENGINEERING_PRINCIPLES.md §8 keeps decisions out of widgets; it does not ask for a bloc
/// where there is no decision).
///
/// [ThemeMode.system] is the default because the parent app is opened in a hurry, and the
/// device setting is the choice the parent already made once for every app on the phone.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.initial = ThemeMode.system]);

  /// Cycles system → light → dark → system.
  ///
  /// Returning to `system` matters: without it, a parent who taps once can never get back
  /// to following the device's own night schedule.
  void cycle() {
    value = switch (value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  void set(ThemeMode mode) => value = mode;
}

/// Makes the [ThemeController] reachable from any screen.
///
/// An [InheritedNotifier] so the widgets that display the current mode rebuild when it
/// changes, without the app root rebuilding the whole tree on every toggle.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, or null outside a [ThemeScope].
  ///
  /// Nullable by design: a widget pumped in a test host has no scope, and a screen that
  /// only offers a theme toggle should render without one rather than crash.
  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;

  static ThemeMode modeOf(BuildContext context) =>
      maybeOf(context)?.value ?? ThemeMode.system;
}

/// Describes a [ThemeMode] for display and for screen readers.
///
/// Lives beside the controller so the icon, the tooltip, and the announced label cannot
/// drift apart — a toggle whose icon says "dark" and whose label says "light" is worse than
/// no label at all (docs/05-ui/ACCESSIBILITY.md).
extension ThemeModeDisplay on ThemeMode {
  IconData get icon => switch (this) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  String get label => switch (this) {
        ThemeMode.system => 'Match device',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}
