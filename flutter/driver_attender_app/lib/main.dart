import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app_config.dart';
import 'app/dependencies.dart';
import 'app/language_switcher_button.dart';
import 'app/theme.dart';
import 'core/session/session_manager.dart';
import 'features/login/ui/login_route.dart';
import 'features/sync/widgets/live_sync_status_banner.dart';
import 'features/trips/bloc/duty_bloc.dart';
import 'features/trips/ui/duty_screen.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_extensions.dart';

Future<void> main() async {
  // Required before touching the keychain or the database: both are platform channels.
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies =
      await AppDependencies.bootstrap(AppConfig.fromEnvironment());

  runApp(GuardianDriverApp(dependencies: dependencies));
}

/// Stateful only so it can rebuild `MaterialApp` when [AppDependencies.localeController]
/// changes (ADR-0013) — everything else about this widget is as static as it was before.
class GuardianDriverApp extends StatefulWidget {
  const GuardianDriverApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<GuardianDriverApp> createState() => _GuardianDriverAppState();
}

class _GuardianDriverAppState extends State<GuardianDriverApp> {
  @override
  Widget build(BuildContext context) {
    // Above MaterialApp so every route can reach the dependencies without them being passed
    // through constructors, and without a global.
    return DependencyScope(
      dependencies: widget.dependencies,
      child: ValueListenableBuilder<Locale?>(
        valueListenable: widget.dependencies.localeController,
        builder: (context, locale, _) => MaterialApp(
          // The product name, not description copy — a brand name is invariant across
          // locales (ADR-0013 does not bring the OS-level task-switcher title into scope;
          // see the driver_attender_app localisation report for this call).
          title: 'Guardian Driver',
          theme: buildDriverTheme(Brightness.light),
          darkTheme: buildDriverTheme(Brightness.dark),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Chooses between signing in and being on duty.
///
/// Driven by [SessionManager]'s stream rather than by navigation, so a session that ends
/// while the app is open — a driver deactivated mid-shift, a refresh token detected as
/// reused (BR-IAM-007, BR-IAM-009) — takes the user off the duty screen immediately,
/// wherever they had navigated to.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final sessionManager = DependencyScope.of(context).sessionManager;

    return StreamBuilder<AuthStatus>(
      stream: sessionManager.statusStream,
      initialData: sessionManager.status,
      builder: (context, snapshot) {
        return switch (snapshot.data) {
          // Only reachable if the stored session has not been read yet. `bootstrap` awaits
          // that before the first frame, so in practice this is a guard rather than a state
          // a driver sees.
          null || AuthUnknown() => const _LaunchScreen(),
          AuthSignedOut(:final reason) => LoginRoute(signedOutReason: reason),
          AuthSignedIn() => const _DutyScreen(),
        };
      },
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: context.l10n.launchScreenStartingLabel,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// The driver's home once signed in.
///
/// **No trip is loaded, because the trip and manifest features are not built yet.** This
/// screen says so rather than showing an invented manifest — a fake student list in a
/// boarding app is exactly the pseudo-production surface FLUTTER_APP_INSTRUCTIONS.md
/// forbids, and at a glance it would be indistinguishable from a real one.
///
/// Everything on this screen is real: the sync banner reports the actual state of the
/// encrypted outbound queue, and signing out drains that queue and wipes the local store.
class _DutyScreen extends StatelessWidget {
  const _DutyScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dependencies = DependencyScope.of(context);
    final user = switch (dependencies.sessionManager.status) {
      AuthSignedIn(:final session) => session.user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dutyScreenTitle),
        actions: [
          LanguageSwitcherButton(controller: dependencies.localeController),
          IconButton(
            tooltip: l10n.signOut,
            iconSize: 28,
            // Signing out on a shared handset wipes this device's local records, so the
            // control is deliberately not adjacent to anything used during a route.
            constraints: const BoxConstraints(
              minWidth: kDriverTouchTarget,
              minHeight: kDriverTouchTarget,
            ),
            onPressed: () => _confirmSignOut(context, dependencies),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          const LiveSyncStatusBanner(),
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DriverSpacing.md,
                vertical: DriverSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.dutyScreenSignedInAs(user.displayName),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(
            child: BlocProvider<DutyBloc>(
              create: (_) => DutyBloc(
                repository: dependencies.tripRepository,
                clock: dependencies.clock,
              ),
              child: const DutyBody(),
            ),
          ),
        ],
      ),
    );
  }

  /// Signing out is irreversible on this device: it wipes the encrypted local store,
  /// including anything still queued. That is one of the few actions
  /// DRIVER_ATTENDANT_APP.md permits a confirmation dialog for.
  Future<void> _confirmSignOut(
    BuildContext context,
    AppDependencies dependencies,
  ) async {
    final l10n = context.l10n;
    final pending = dependencies.syncEngine.status.pendingCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutDialogTitle),
        content: Text(
          pending == 0
              ? l10n.signOutDialogBodyNoPending
              : l10n.signOutDialogBodyPending(pending),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await dependencies.signOut();
    }
  }
}
