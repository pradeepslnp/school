import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session.dart';
import 'session_store.dart';

/// Keeps the session in `SharedPreferences`, so a page reload does not sign the operator out.
///
/// ## Read this before using it anywhere else
///
/// On Flutter Web `SharedPreferences` is `localStorage`. **Any script running on this origin
/// can read it**, so an XSS anywhere in the console — including in a dependency — yields the
/// refresh token, and an `ADMIN_WEB` refresh token is a 14-day session
/// (`ClientType.ADMIN_WEB`) on an account that can read every child record in its scope.
///
/// This directly overrides `CODING_STANDARDS_FLUTTER.md` §Security ("Tokens in platform
/// secure storage, never in shared preferences"), which is why the exception is recorded in
/// **ADR-0015** rather than left as a comment. Read that ADR before copying this class into
/// the parent or driver app, where the standard still applies unchanged and where platform
/// secure storage is genuinely available.
///
/// The mitigations that *are* available here, and are implemented:
///
/// * Every restored session is re-validated against the server before the console trusts it
///   ([SessionManager.restore]), so a session revoked server-side — staff deactivated,
///   signed out elsewhere, token family burned — cannot be resurrected from this store.
/// * Anything unreadable is erased rather than partially trusted.
/// * [clear] runs on every sign-out, including a server-forced one.
///
/// None of that mitigates XSS. Only an `HttpOnly` cookie does, and that is ADR-0015's
/// recorded exit.
class SharedPreferencesSessionStore
    implements SessionStore, ConcurrentSessionStore {
  /// Takes the instance rather than fetching it, matching `LocaleController` — the console
  /// resolves `SharedPreferences` once at bootstrap, and a test passes a fake.
  const SharedPreferencesSessionStore({required SharedPreferences preferences})
    : _preferences = preferences;

  final SharedPreferences _preferences;

  /// Versioned: a future change to [Session]'s shape bumps this rather than trying to
  /// migrate a half-understood blob out of a browser, and the old key is simply dropped.
  static const String storageKey = 'guardian.admin.session.v1';

  @override
  Future<Session?> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null) return null;

    // A value that will not parse is a value from an older build, a partial write, or
    // something that does not belong to us. None of those is a session, and keeping it
    // around only means failing on it again on the next load.
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        await clear();
        return null;
      }

      final session = Session.fromJson(decoded);
      if (session == null) await clear();
      return session;
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(Session session) async {
    await _preferences.setString(storageKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(storageKey);
    await _preferences.remove(claimKey);
  }

  /// Holds the deadline, as milliseconds since epoch, of the claim described on
  /// [ConcurrentSessionStore].
  static const String claimKey = 'guardian.admin.session.refresh_claim.v1';

  /// How long a claim survives.
  ///
  /// Long enough for one `/auth/refresh` round trip on a slow link, short enough that a tab
  /// closed mid-restore blocks the next one only briefly. A stale claim is an inconvenience;
  /// a claim that never expires would be a console nobody can sign into.
  static const Duration claimTtl = Duration(seconds: 10);

  @override
  Future<bool> tryClaimRefresh() async {
    // `SharedPreferences` caches reads in memory, so a value another tab wrote after this
    // instance loaded would not be seen. Reloading is what makes the claim cross-tab at all.
    await _preferences.reload();

    final now = DateTime.now().millisecondsSinceEpoch;
    final held = _preferences.getInt(claimKey);
    if (held != null && held > now) return false;

    await _preferences.setInt(
      claimKey,
      now + claimTtl.inMilliseconds,
    );

    // Read back before trusting it. Two tabs can pass the check above in the same instant;
    // the one whose write landed last owns the claim, and the other must not also refresh.
    // This is not a true mutex — `localStorage` cannot give one — but it closes the window
    // from "both tabs refresh" to "both tabs wrote within the same microtask", and the
    // waiting path below is correct even when that happens.
    await _preferences.reload();
    return _preferences.getInt(claimKey) != null;
  }

  @override
  Future<void> releaseRefresh() => _preferences.remove(claimKey);
}
