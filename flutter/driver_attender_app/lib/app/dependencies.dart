import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/locale/locale_controller.dart';
import '../core/network/rest_client.dart';
import '../core/offline/outbound_queue.dart';
import '../core/offline/outbound_transport.dart';
import '../core/offline/sync_engine.dart';
import '../core/offline/sync_metadata.dart';
import '../core/session/session_manager.dart';
import '../core/session/session_store.dart';
import '../core/storage/database_key.dart';
import '../core/storage/local_database.dart';
import '../core/storage/secret_store.dart';
import '../core/time/clock.dart';
import '../features/login/data_provider/login_data_provider.dart';
import '../features/login/repository/login_repository.dart';
import 'app_config.dart';

/// The app's composition root.
///
/// Everything is constructed once, here, and injected downwards
/// (ENGINEERING_PRINCIPLES.md §5). There is no service locator and no mutable static state:
/// a widget or a bloc that could reach a singleton could not be tested without it, and the
/// pieces this class wires together — an encrypted database, a keychain, an HTTP client —
/// are precisely the ones a test must be able to replace.
class AppDependencies {
  AppDependencies._({
    required this.config,
    required this.clock,
    required this.secrets,
    required this.localDatabase,
    required this.restClient,
    required this.sessionManager,
    required this.loginRepository,
    required this.outboundQueue,
    required this.syncEngine,
    required this.localeController,
  });

  final AppConfig config;
  final Clock clock;
  final SecretStore secrets;
  final LocalDatabase localDatabase;
  final RestClient restClient;
  final SessionManager sessionManager;
  final LoginRepository loginRepository;
  final OutboundQueue outboundQueue;
  final SyncEngine syncEngine;

  /// The driver's language preference (ADR-0013). Loaded during [bootstrap], alongside the
  /// keychain and database reads it already awaits, so the first frame already renders in
  /// the right language instead of flashing English and then switching.
  final LocaleController localeController;

  StreamSubscription<AuthStatus>? _authSubscription;

  /// Builds and starts everything.
  ///
  /// Called once from `main`, before the first frame. The awaits here are the reason for a
  /// brief launch screen: reading the keychain and opening an encrypted database are real
  /// I/O, and starting the UI first would mean a driver could tap sign-in before the store
  /// that holds the session exists.
  static Future<AppDependencies> bootstrap(AppConfig config) async {
    const clock = SystemClock();
    final secrets = PlatformSecretStore();

    // ADR-0013: the driver's language preference is not secret, so it is read from
    // shared_preferences rather than the keychain-backed SecretStore above — but it is read
    // here, before the first frame, for the same reason: nothing should render and then
    // switch language a moment later.
    final localeController = await LocaleController.load();

    final localDatabase = LocalDatabase(
      key: DatabaseKey(secrets: secrets),
    );

    final outboundQueue = SqliteOutboundQueue(
      database: localDatabase,
      clock: clock,
    );

    // The session manager and the HTTP client each need the other: every request needs a
    // token, and obtaining a token is a request. The knot is tied with a `late` binding and
    // closures rather than by giving either one a setter — the closures are only invoked
    // once a request is in flight, by which point both objects exist, and neither type ends
    // up with a mutable field that could be repointed later.
    late final SessionManager sessionManager;

    final restClient = RestClient(
      baseUrl: config.apiBaseUrl,
      clientType: LoginDataProvider.clientType,
      clock: clock,
      accessTokenProvider: () => sessionManager.accessToken(),
      onUnauthorized: () => sessionManager.handleUnauthorized(),
    );

    final loginRepository = LoginRepository(
      dataProvider: LoginDataProvider(client: restClient),
      clock: clock,
    );

    sessionManager = SessionManager(
      store: SessionStore(secrets: secrets),
      refresher: loginRepository,
      clock: clock,
      onSessionEnded: () async {
        // ADR-0008: the local store is wiped on logout and on remote session revocation.
        // Ordered database-then-keychain so an interruption leaves unreadable ciphertext
        // rather than a live key beside a readable file.
        await localDatabase.wipe();
        await secrets.deleteAll();
      },
    );

    final syncEngine = SyncEngine(
      queue: outboundQueue,
      transport: OutboundTransport(client: restClient, clock: clock),
      metadata: SyncMetadata(database: localDatabase),
      clock: clock,
      onSessionEnded: () =>
          sessionManager.signOut(reason: SignOutReason.revokedByServer),
    );

    final dependencies = AppDependencies._(
      config: config,
      clock: clock,
      secrets: secrets,
      localDatabase: localDatabase,
      restClient: restClient,
      sessionManager: sessionManager,
      loginRepository: loginRepository,
      outboundQueue: outboundQueue,
      syncEngine: syncEngine,
      localeController: localeController,
    );

    await sessionManager.restore();
    await dependencies._followAuthStatus();

    return dependencies;
  }

  /// Runs the sync engine only while somebody is signed in.
  ///
  /// Draining without a session would send unauthenticated requests that can only fail, and
  /// on a metered mobile link that is battery and data spent on a guaranteed 401.
  Future<void> _followAuthStatus() async {
    if (sessionManager.status is AuthSignedIn) {
      await syncEngine.start();
    }

    _authSubscription = sessionManager.statusStream.listen((status) {
      if (status is AuthSignedIn) unawaited(syncEngine.start());
    });
  }

  /// Signs out, giving the queue a last chance to empty first.
  ///
  /// The drain is attempted, not required: signing out wipes the local store either way
  /// (see [SessionManager.signOut]). A driver handing over a shared handset in a depot with
  /// no signal still gets a clean device — losing an unsent record is bad, and leaving
  /// another shift's child data on someone else's phone is worse.
  Future<void> signOut() async {
    await syncEngine.drain();
    await loginRepository.revokeSessionOnServer();
    await sessionManager.signOut();
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await syncEngine.stop();
    await outboundQueue.close();
    await sessionManager.dispose();
    await localDatabase.close();
    restClient.close();
    localeController.dispose();
  }
}

/// Makes [AppDependencies] available to the widget tree.
///
/// An `InheritedWidget` rather than a global: a test pumps a subtree under its own scope with
/// fakes, and a widget that forgot to be given dependencies fails loudly at build time
/// instead of quietly picking up production ones.
class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DependencyScope>();
    assert(scope != null, 'No DependencyScope above this widget');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(DependencyScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
