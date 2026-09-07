import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_config.dart';
import 'app/locale_controller.dart';
import 'app/theme.dart';
import 'app/theme_controller.dart';
import 'core/l10n_extensions.dart';
import 'features/home/ui/home_route.dart';
import 'features/login/repository/models/session.dart';
import 'features/login/ui/login_screen.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads the calendar-name (weekday/month) data `DateFormat` needs for a non-English locale
  // (journey_history_screen.dart, notifications_screen.dart) — without this, formatting a
  // date in `kn` throws at runtime rather than falling back quietly.
  await initializeDateFormatting();
  // Awaited before the first frame (ADR-0013): a SharedPreferences read is fast and bounded,
  // so this does not risk blocking indefinitely the way a network call would.
  final locale = await LocaleController.load();
  runApp(GuardianParentApp(config: AppConfig.fromEnvironment(), localeController: locale));
}

class GuardianParentApp extends StatefulWidget {
  const GuardianParentApp({super.key, required this.config, required this.localeController});

  final AppConfig config;
  final LocaleController localeController;

  @override
  State<GuardianParentApp> createState() => _GuardianParentAppState();
}

class _GuardianParentAppState extends State<GuardianParentApp> {
  /// Owned by the root so the preference survives navigation, and disposed with it.
  final _theme = ThemeController();

  @override
  void dispose() {
    _theme.dispose();
    widget.localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: widget.localeController,
      child: ThemeScope(
        controller: _theme,
        child: ValueListenableBuilder<Locale>(
          valueListenable: widget.localeController,
          builder: (context, locale, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: _theme,
              builder: (context, mode, _) {
                return MaterialApp(
                  onGenerateTitle: (context) => context.l10n.appTitle,
                  theme: buildParentTheme(Brightness.light),
                  darkTheme: buildParentTheme(Brightness.dark),
                  // Both themes are always supplied, so the device's own night schedule works
                  // without the parent choosing anything.
                  themeMode: mode,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  // The generated list already includes the Global*Localizations delegates
                  // (flutter_localizations is a dependency), so nothing else needs adding here.
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  home: _RootRoute(config: widget.config),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Chooses between login and home.
///
/// Holds the session in memory only. Persisting it needs secure storage and refresh
/// rotation (ADR-0006), which is the next piece of work — writing a token to plain
/// preferences in the meantime would be the kind of shortcut INSTRUCTIONS.md rules out.
class _RootRoute extends StatefulWidget {
  const _RootRoute({required this.config});

  final AppConfig config;

  @override
  State<_RootRoute> createState() => _RootRouteState();
}

class _RootRouteState extends State<_RootRoute> {
  Session? _session;

  @override
  Widget build(BuildContext context) {
    final session = _session;

    if (session == null) {
      return LoginScreen(
        apiBaseUrl: widget.config.apiBaseUrl,
        onAuthenticated: (session) => setState(() => _session = session),
      );
    }

    return HomeRoute(
      apiBaseUrl: widget.config.apiBaseUrl,
      guardianName: session.user.firstName,
      // Read at call time rather than captured, so a rotated token is used without
      // rebuilding the route (ADR-0006).
      accessToken: () async => _session?.accessToken,
      // The session lives in memory only, so ending it returns to login. Silent refresh
      // needs secure storage and rotation, which is the next piece of work.
      onUnauthorized: () async {
        if (mounted) setState(() => _session = null);
      },
    );
  }
}
