import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the driver's language preference and persists it locally (ADR-0013).
///
/// A [ValueNotifier] rather than a BLoC — mirrors `parent_app`'s `ThemeController`
/// precedent for exactly the same reason: there is no event to validate, no server to ask,
/// and no failure state, so a bloc here would be ceremony around a single nullable enum-like
/// value (ENGINEERING_PRINCIPLES.md §8 keeps decisions out of widgets; it does not ask for a
/// bloc where there is no decision).
///
/// `value == null` means "follow the device locale" — [GuardianDriverApp] passes that
/// straight through as `MaterialApp.locale`, and Flutter's own resolution already implements
/// ADR-0013's default ("follow system locale when it's `en` or `kn`, else `en`") by matching
/// the device locale against `supportedLocales` and falling back to the first supported
/// locale (`en`, listed first) when nothing matches. No extra fallback logic is needed here.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController._(this._preferences, super.initial);

  static const _preferenceKey = 'guardian_driver.locale';

  /// Language codes this app ships a bundled ARB for. Kept in sync with
  /// `AppLocalizations.supportedLocales` (generated from `l10n.yaml`) — this list exists
  /// separately only so `LocaleController` does not need to import the generated file.
  static const supportedLanguageCodes = <String>['en', 'kn'];

  final SharedPreferencesAsync _preferences;

  /// Reads the persisted preference, if any.
  ///
  /// Called once from [AppDependencies.bootstrap], alongside the keychain and database reads
  /// it already awaits — this app's established idiom is to read everything needed before
  /// the first frame in one place, rather than showing a screen that then jumps to a
  /// different language a moment later.
  static Future<LocaleController> load({
    SharedPreferencesAsync? preferences,
  }) async {
    final prefs = preferences ?? SharedPreferencesAsync();
    final storedCode = await prefs.getString(_preferenceKey);
    return LocaleController._(prefs, _localeFor(storedCode));
  }

  static Locale? _localeFor(String? languageCode) {
    if (languageCode == null) return null;
    if (!supportedLanguageCodes.contains(languageCode)) return null;
    return Locale(languageCode);
  }

  /// Sets the driver's language choice and persists it.
  ///
  /// `null` clears the override and returns to following the device locale.
  Future<void> setLocale(Locale? locale) async {
    value = locale;
    if (locale == null) {
      await _preferences.remove(_preferenceKey);
    } else {
      await _preferences.setString(_preferenceKey, locale.languageCode);
    }
  }
}
