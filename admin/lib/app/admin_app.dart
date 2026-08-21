import 'package:flutter/material.dart';

import 'console_router.dart';
import 'dependencies.dart';
import 'theme.dart';

/// The console application.
///
/// Owns the router and the dependency scope, and nothing else. Kept out of `main.dart` so a
/// widget test can pump it with fake dependencies and no bootstrap.
class GuardianAdminApp extends StatefulWidget {
  const GuardianAdminApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<GuardianAdminApp> createState() => _GuardianAdminAppState();
}

class _GuardianAdminAppState extends State<GuardianAdminApp> {
  late final ConsoleRouterDelegate _routerDelegate = ConsoleRouterDelegate(
    sessionManager: widget.dependencies.sessionManager,
    onSignOut: widget.dependencies.signOut,
  );

  static const ConsoleRouteInformationParser _routeParser =
      ConsoleRouteInformationParser();

  @override
  void dispose() {
    _routerDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DependencyScope(
      dependencies: widget.dependencies,
      child: MaterialApp.router(
        title: 'Guardian Admin',
        theme: buildAdminTheme(Brightness.light),
        darkTheme: buildAdminTheme(Brightness.dark),
        // Follows the operating system. An operator who has chosen a dark desktop has
        // usually done so for a reason — glare, or a long shift — and overriding it here
        // would be the console deciding it knows better.
        themeMode: ThemeMode.system,
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeParser,
      ),
    );
  }
}
