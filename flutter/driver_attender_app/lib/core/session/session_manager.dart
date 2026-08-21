import 'dart:async';

import '../domain.dart';
import '../time/clock.dart';
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

/// Why a session ended. Determines what the user is told and what gets erased.
enum SignOutReason {
  /// The driver signed out — end of shift, or handing the device over.
  userRequested,

  /// The server revoked the session: staff deactivation, or refresh-token reuse
  /// (BR-IAM-007, BR-IAM-009). Not the user's doing, and they should be told so.
  revokedByServer,

  /// The refresh token no longer works and could not be replaced.
  refreshFailed,
}

/// Who is signed in, if anyone.
sealed class AuthStatus {
  const AuthStatus();
}

/// Before the stored session has been read. Distinct from signed out so the app does not
/// flash a login screen at a driver who is already authenticated.
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

/// Owns the session for the life of the app.
///
/// Three jobs, and nothing else: hold the current session, keep its access token fresh, and
/// end it cleanly. Signing in is the login feature's business; this class only adopts the
/// result.
///
/// **Not a singleton.** Constructed once at the composition root and injected
/// (ENGINEERING_PRINCIPLES.md §5), so a test builds one with a fake store and a fake clock
/// and never touches the keychain.
class SessionManager {
  SessionManager({
    required SessionStore store,
    required SessionRefresher refresher,
    required Clock clock,
    Future<void> Function()? onSessionEnded,
    this.refreshWindow = const Duration(minutes: 2),
  })  : _store = store,
        _refresher = refresher,
        _clock = clock,
        _onSessionEnded = onSessionEnded;

  /// How far ahead of expiry to refresh.
  ///
  /// Two minutes against a fifteen-minute token (ADR-0006). Wide enough to cover a slow
  /// request on a weak link, narrow enough that the app is not refreshing constantly.
  final Duration refreshWindow;

  final SessionStore _store;
  final SessionRefresher _refresher;
  final Clock _clock;

  /// Erases everything tied to the ended session — in practice, the encrypted local store
  /// (ADR-0008). Injected rather than imported so `core/session` does not depend on
  /// `core/offline`, and so a test can assert the wipe happened without a database.
  final Future<void> Function()? _onSessionEnded;

  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  AuthStatus _status = const AuthUnknown();
  Session? _session;
  Future<Session?>? _refreshInFlight;

  AuthStatus get status => _status;

  Stream<AuthStatus> get statusStream => _statusController.stream;

  /// Reads any stored session and publishes the starting state.
  Future<void> restore() async {
    final stored = await _store.read();
    if (stored == null) {
      _emit(const AuthSignedOut());
      return;
    }

    _session = stored;
    _emit(AuthSignedIn(stored));

    // An expired stored session is not signed out: the refresh token outlives the access
    // token by a week (ClientType.DRIVER_APP), so the usual case here is a driver opening
    // the app at the start of a shift, and refreshing is what keeps them from re-entering an
    // OTP on a bus.
    if (stored.isExpiringWithin(refreshWindow, now: _clock.nowUtc())) {
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
  /// middle of a boarding submission.
  Future<String?> accessToken() async {
    final session = _session;
    if (session == null) return null;

    if (!session.isExpiringWithin(refreshWindow, now: _clock.nowUtc())) {
      return session.accessToken;
    }

    final refreshed = await _refresh();
    return refreshed?.accessToken;
  }

  /// Called by [RestClient] on any 401.
  ///
  /// Refreshes once; it does not retry the failed request. The caller decides what to do with
  /// the failure — for a queued safety record that means staying queued and going out on the
  /// next drain with the new token, which is exactly right: nothing is lost, and nothing is
  /// sent twice.
  Future<void> handleUnauthorized() async {
    if (_session == null) return;
    await _refresh();
  }

  /// Rotates the session. **Single-flight.**
  ///
  /// Concurrent 401s from a drain of fifty queued records must not fire fifty refreshes: the
  /// refresh token is single-use, so the second call would present an already-consumed token,
  /// the server would read that as theft, and the whole token family — including the driver
  /// mid-route — would be revoked (BR-IAM-009). The de-duplication here is not an
  /// optimisation.
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
        // A transport failure is not a dead session — the bus is in a coverage gap. The
        // session is kept so the driver is not thrown to a login screen they cannot complete
        // without a network, and the next drain tries again.
        if (code == ErrorCode.dependencyUnavailable) return null;

        await signOut(
          reason: code.endsSession
              ? SignOutReason.revokedByServer
              : SignOutReason.refreshFailed,
        );
        return null;
    }
  }

  /// Ends the session and erases what it protected.
  ///
  /// The local wipe runs **whatever the reason and whether or not the server call succeeded**
  /// — this is a shared device, and a driver signing off must not leave a previous shift's
  /// child data on it (ADR-0008, AUTHENTICATION_API.md §logout).
  ///
  /// Note what this destroys: any records still queued. Callers should drain first where
  /// they can. Keeping them would mean retaining child PII on a handset that has just been
  /// handed to someone else, which is the worse of the two failures.
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
}
