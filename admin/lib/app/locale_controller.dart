import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The console's active display language, persisted across sessions.
///
/// The direct analogue, in this app, of the other two Flutter apps' `ThemeController`
/// precedent (ADR-0013 §5): a `ValueNotifier`-backed cross-cutting app-shell preference,
/// constructed once at the composition root and injected via [AppDependencies] rather than
/// reached through a service locator — the same reasoning `WorkspaceContext` documents for
/// itself. It differs from `WorkspaceContext` in one respect: that class is deliberately
/// in-memory only (a same-tab convenience), while a chosen *language* is exactly the kind of
/// preference `shared_preferences` exists for — it should still be Kannada tomorrow, not just
/// this tab.
///
/// Unlike `themeMode` (`admin_app.dart`, deliberately always `ThemeMode.system` — an operator's
/// OS-level dark-mode choice is respected, not second-guessed), language has no equivalent
/// "the platform already decided this for a good reason" case: this console offers an explicit
/// in-app switcher (see `LanguageSwitcher`) on top of the system-locale default below.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController._(super.initial, this._preferences);

  static const _preferenceKey = 'admin_console_locale';

  /// The locales this console ships copy for (ADR-0013). Kept in one place so the switcher,
  /// `MaterialApp.supportedLocales`, and the bootstrap default can never drift apart.
  static const List<Locale> supportedLocales = [Locale('en'), Locale('kn')];

  final SharedPreferences _preferences;

  /// Restores a previously-chosen language, or falls back to the platform locale when it is
  /// `en` or `kn`, else English (ADR-0013 §5 default rule).
  ///
  /// Called once from `AppDependencies.bootstrap`, before the first frame — the same shape as
  /// `SessionManager.restore()` — so the console never flashes English at an operator who has
  /// already chosen Kannada.
  static Future<LocaleController> bootstrap({
    required Locale platformLocale,
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final stored = _resolve(prefs.getString(_preferenceKey));
    final initial = stored ?? _resolve(platformLocale.languageCode) ?? const Locale('en');
    return LocaleController._(initial, prefs);
  }

  static Locale? _resolve(String? languageCode) {
    if (languageCode == null) return null;
    for (final locale in supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }

  /// Switches the console's language immediately and persists the choice for the next sign-in.
  Future<void> setLocale(Locale locale) async {
    if (value == locale) return;
    value = locale;
    await _preferences.setString(_preferenceKey, locale.languageCode);
  }
}
