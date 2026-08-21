import 'session.dart';

/// Where the console keeps the current session.
///
/// A port rather than a concrete class, because *where* is the open question and the answer
/// is a backend decision — see [InMemorySessionStore] for why the browser has nowhere safe
/// to put a refresh token today, and what would change that.
///
/// Declared as an interface so the change, when it comes, replaces one implementation and
/// touches nothing else (ENGINEERING_PRINCIPLES.md §5).
abstract interface class SessionStore {
  Future<Session?> read();

  Future<void> write(Session session);

  Future<void> clear();
}

/// Holds the session in memory, for the lifetime of the browser tab.
///
/// ## Why not `localStorage` or `sessionStorage`
///
/// CODING_STANDARDS_FLUTTER.md §Security requires tokens in platform secure storage and
/// forbids shared preferences. Web storage is the browser's shared preferences: any script
/// running on the origin can read it, so a single XSS anywhere in the console yields a
/// refresh token, and a refresh token for this client is a durable session on an account
/// that can read every child record in its scope (SECURITY_ARCHITECTURE.md — admin web is
/// listed as the *higher privilege* client). `flutter_secure_storage` does not change this
/// on web: its web backend encrypts into `localStorage` with a key that also lives in
/// `localStorage`.
///
/// ## What this costs, plainly
///
/// A page reload signs the operator out. ADMIN_WEB.md describes a desk tool with several
/// tabs open, so this is a real cost, not a theoretical one — and it is stated here rather
/// than buried, because the fix is a backend change and someone has to decide to make it.
///
/// ## The fix
///
/// A refresh token delivered as an `HttpOnly; Secure; SameSite=Strict` cookie, which
/// JavaScript cannot read and the browser replays only to `/auth/refresh`. That requires the
/// API to set the cookie at sign-in — a change to a contract that currently returns the
/// refresh token in the response body (AUTHENTICATION_API.md) — so it needs an ADR, not a
/// client-side workaround.
///
/// Until then this is the honest implementation: no persistence, no false durability, and
/// nothing readable by a script (ENGINEERING_PRINCIPLES.md §15).
class InMemorySessionStore implements SessionStore {
  Session? _session;

  @override
  Future<Session?> read() async => _session;

  @override
  Future<void> write(Session session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
