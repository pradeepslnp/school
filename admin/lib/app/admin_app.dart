import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations_extension.dart';
import '../l10n/generated/app_localizations.dart';
import 'console_router.dart';
import 'dependencies.dart';
import 'locale_controller.dart';
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
      // The console's language, unlike its theme, is driven by an explicit in-app control
      // (see `LanguageSwitcher`) rather than left to follow the platform unconditionally — see
      // `LocaleController`'s doc comment for why that precedent does not carry over. Rebuilding
      // `MaterialApp.router` on every change is what makes a switch take effect immediately,
      // without a restart (ADR-0013 verification #2).
      child: ValueListenableBuilder<Locale>(
        valueListenable: widget.dependencies.localeController,
        builder: (context, locale, _) {
          return MaterialApp.router(
            // `onGenerateTitle`, not `title`: it is called with a context that already sits
            // below `MaterialApp`'s own `Localizations` widget, which a literal `title:` value
            // does not have access to — `context.l10n` here would otherwise resolve against
            // nothing.
            onGenerateTitle: (context) => context.l10n.appTitle,
            theme: buildAdminTheme(Brightness.light),
            darkTheme: buildAdminTheme(Brightness.dark),
            // Follows the operating system. An operator who has chosen a dark desktop has
            // usually done so for a reason — glare, or a long shift — and overriding it here
            // would be the console deciding it knows better.
            themeMode: ThemeMode.system,
            locale: locale,
            supportedLocales: LocaleController.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerDelegate: _routerDelegate,
            routeInformationParser: _routeParser,
          );
        },
      ),
    );
  }
}
