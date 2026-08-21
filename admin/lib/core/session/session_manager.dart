import 'dart:async';

import '../domain.dart';
import 'session.dart';
import 'session_store.dart';

/// Exchanges a refresh token for a new session.
///
/// A port, implemented by the login feature's repository. Declared here so `core/` does not
/// import a feature: the session lifecycle belongs to the app, and the knowledge of which
/// endpoint rotates a token belongs to the feature that owns that endpoint.
abstract interface class SessionRefresher {
  Future<Result<Session>> refreshSession(String refreshToken);
}

/// Why a session ended. Determines what the operator is told.
enum SignOutReason {
  /// The operator signed out.
  userRequested,

  /// The server revoked the session: staff deactivation, or refresh-token reuse
  /// (BR-IAM-007, BR-IAM-009). Not the operator's doing, and they should be told so.
  revokedByServer,

  /// The refresh token no longer works and could not be replaced.
  refreshFailed,
}

/// Who is signed in, if anyone.
sealed class AuthStatus {
  const AuthStatus();
}

/// Before the stored session has been read. Distinct from signed out so the console does not
/// flash a sign-in screen at someone who is already authenticated.
final class AuthUnknown extends AuthStatus {
  const AuthUnknown();
}

final class AuthSignedOut extends AuthStatus {
  const AuthSignedOut([this.reason]);

  final SignOutReason? reason;
}

final class AuthSignedIn extends AuthStatus {
  const AuthSignedIn(this.session);

  final Session session;
}

/// Owns the session for the life of the console.
///
/// Three jobs and nothing else: hold the current session, keep its access token fresh, and
/// end it cleanly. Signing in is the login feature's business; this class only adopts the
/// result.
///
/// Publishes changes through a broadcast stream rather than a Flutter `ChangeNotifier`,
/// keeping `core/session` free of `package:flutter` so it stays testable without a widget
/// binding and portable if ADR-0003 is reversed.
///
/// **Not a singleton.** Constructed once at the composition root and injected
/// (ENGINEERING_PRINCIPLES.md §5), so a test builds one with a fake store and a fake clock.
class SessionManager {
  SessionManager({
    required SessionStore store,
    required SessionRefresher refresher,
    DateTime Function()? now,
    Future<void> Function()? onSessionEnded,
    this.refreshWindow = const Duration(minutes: 2),
  })  : _store = store,
        _refresher = refresher,
        _now = now ?? _systemNowUtc,
        _onSessionEnded = onSessionEnded;

  /// How far ahead of expiry to refresh.
  ///
  /// Two minutes against a fifteen-minute token (ADR-0006). Wide enough to cover a slow
  /// request, narrow enough that the console is not refreshing constantly.
  final Duration refreshWindow;

  final SessionStore _store;
  final SessionRefresher _refresher;

  /// The clock, injected. A test asserts the refresh-window behaviour by moving this rather
  /// than by waiting fifteen real minutes.
  final DateTime Function() _now;

  /// Erases anything tied to the ended session — cached tenant data, in-flight views.
  /// Injected rather than imported so `core/session` depends on no feature, and so a test
  /// can assert the clean-up happened.
  final Future<void> Function()? _onSessionEnded;

  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  AuthStatus _status = const AuthUnknown();
  Session? _session;
  Future<Session?>? _refreshInFlight;

  AuthStatus get status => _status;

  Stream<AuthStatus> get statusStream => _statusController.stream;

  /// The signed-in user, or null. Convenience for the shell, which renders the account
  /// control on every screen.
  AuthenticatedUser? get currentUser => _session?.user;

  /// Reads any stored session and publishes the starting state.
  ///
  /// With [InMemorySessionStore] this always resolves to signed out on a fresh page load.
  /// The step is not redundant: it is the seam the durable store slots into, and it is what
  /// keeps [AuthUnknown] a real state rather than a state the console skips.
  Future<void> restore() async {
    final stored = await _store.read();
    if (stored == null) {
      _emit(const AuthSignedOut());
      return;
    }

    _session = stored;
    _emit(AuthSignedIn(stored));

    if (stored.isExpiringWithin(refreshWindow, now: _now())) {
      unawaited(_refresh());
    }
  }

  /// Adopts a session produced by the login feature.
  Future<void> adopt(Session session) async {
    _session = session;
    await _store.write(session);
    _emit(AuthSignedIn(session));
  }

  /// A valid access token, or null when there is no usable session.
  ///
  /// This is what [RestClient] calls before every authenticated request. Refreshing here —
  /// ahead of expiry rather than after a 401 — is what keeps a token from expiring in the
  /// middle of an operator's action.
  Future<String?> accessToken() async {
    final session = _session;
    if (session == null) return null;

    if (!session.isExpiringWithin(refreshWindow, now: _now())) {
      return session.accessToken;
    }

    final refreshed = await _refresh();
    return refreshed?.accessToken;
  }

  /// Called by [RestClient] on any 401.
  ///
  /// Refreshes once; it does not retry the failed request. The caller decides what to do
  /// with the failure, because only the caller knows whether repeating it is safe.
  Future<void> handleUnauthorized() async {
    if (_session == null) return;
    await _refresh();
  }

  /// Rotates the session. **Single-flight.**
  ///
  /// A console screen makes several concurrent requests — a dashboard loads alerts, trip
  /// counts, and student counts at once. If the token expires while they are in flight, all
  /// of them come back 401 together. Without this de-duplication each would fire its own
  /// refresh, the second would present an already-consumed token, the server would correctly
  /// read that as theft, and the entire token family would be revoked — signing the operator
  /// out mid-incident (BR-IAM-009). The de-duplication is not an optimisation.
  Future<Session?> _refresh() {
    return _refreshInFlight ??=
        _performRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<Session?> _performRefresh() async {
    final current = _session;
    if (current == null) return null;

    final result = await _refresher.refreshSession(current.refreshToken);

    switch (result) {
      case Success(:final value):
        await adopt(value);
        return value;

      case Failure(:final code):
        // An unreachable API is not a dead session. Signing the operator out here would
        // discard a working refresh token because of a dropped connection, and this store
        // cannot get it back — the sign-in would be real, and unnecessary.
        if (code == ErrorCode.dependencyUnavailable) return null;

        await signOut(
          reason: code.endsSession
              ? SignOutReason.revokedByServer
              : SignOutReason.refreshFailed,
        );
        return null;
    }
  }

  /// Ends the session.
  ///
  /// Clears local state whatever the reason and whether or not the server call succeeded.
  /// A sign-out that leaves a usable token in the tab because the network was down is not a
  /// sign-out.
  Future<void> signOut({
    SignOutReason reason = SignOutReason.userRequested,
  }) async {
    _session = null;
    await _store.clear();
    await _onSessionEnded?.call();
    _emit(AuthSignedOut(reason));
  }

  void _emit(AuthStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  Future<void> dispose() => _statusController.close();

  static DateTime _systemNowUtc() => DateTime.now().toUtc();
}
