import 'package:flutter/material.dart';

import 'app/app_config.dart';
import 'app/theme.dart';
import 'app/theme_controller.dart';
import 'features/home/ui/home_route.dart';
import 'features/login/repository/models/session.dart';
import 'features/login/ui/login_screen.dart';

void main() {
  runApp(GuardianParentApp(config: AppConfig.fromEnvironment()));
}

class GuardianParentApp extends StatefulWidget {
  const GuardianParentApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<GuardianParentApp> createState() => _GuardianParentAppState();
}

class _GuardianParentAppState extends State<GuardianParentApp> {
  /// Owned by the root so the preference survives navigation, and disposed with it.
  final _theme = ThemeController();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _theme,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _theme,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'Guardian',
            theme: buildParentTheme(Brightness.light),
            darkTheme: buildParentTheme(Brightness.dark),
            // Both themes are always supplied, so the device's own night schedule works
            // without the parent choosing anything.
            themeMode: mode,
            home: _RootRoute(config: widget.config),
          );
        },
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
