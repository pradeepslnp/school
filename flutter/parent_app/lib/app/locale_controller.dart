import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's language preference (ADR-0013 — interim client-bundled localisation).
///
/// Unlike [ThemeController] there is no continuously-followed "system" mode here: the app
/// only ever ships English and Kannada, so the system locale is consulted once, at startup,
/// to pick a starting value — not re-consulted afterwards. Persisted via `shared_preferences`
/// so the choice survives a restart, unlike [ThemeController], which stays memory-only for a
/// different reason (ADR-0006 — no plaintext auth token storage yet). Locale is not a secret,
/// so persisting it now needs no other prerequisite.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController(Locale initial) : super(initial);

  static const _prefsKey = 'guardian_parent.locale';

  /// The only two locales this app ships (ADR-0013). Kept here rather than deriving from
  /// `AppLocalizations.supportedLocales` so this file has no generated-code dependency.
  static const supportedLocales = [Locale('en'), Locale('kn')];

  /// Builds a controller from the persisted choice, or — if none was ever made — from the
  /// device locale when it is `en` or `kn`, else `en` (ADR-0013).
  ///
  /// Awaited once in `main()` before the first frame: a `SharedPreferences` read is fast and
  /// bounded, so this does not risk blocking indefinitely the way a network call would.
  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    final initial = stored != null && _isSupported(stored)
        ? Locale(stored)
        : _systemDefault();
    return LocaleController(initial);
  }

  static bool _isSupported(String languageCode) =>
      supportedLocales.any((locale) => locale.languageCode == languageCode);

  static Locale _systemDefault() {
    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    return _isSupported(deviceLanguage) ? Locale(deviceLanguage) : const Locale('en');
  }

  /// Switches the active language and persists the choice.
  Future<void> set(Locale locale) async {
    if (!_isSupported(locale.languageCode) || locale == value) return;
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}

/// Makes the [LocaleController] reachable from any screen — the same shape as
/// [ThemeScope], so the two cross-cutting app-shell preferences are threaded identically.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, or null outside a [LocaleScope] — nullable for the same reason
  /// [ThemeScope.maybeOf] is: a widget pumped without a scope should render, not crash.
  static LocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}
