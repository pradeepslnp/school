import 'dart:convert';

import '../storage/secret_store.dart';
import 'session.dart';

/// Persists the session in the platform keychain.
///
/// Not shared preferences (CODING_STANDARDS_FLUTTER.md §Security). On a rooted or lost
/// handset, preferences are a file; the keychain is hardware-backed. The difference is
/// whether a stolen driver phone yields a working token for the rest of its seven-day
/// refresh lifetime.
class SessionStore {
  SessionStore({required SecretStore secrets}) : _secrets = secrets;

  static const String _secretName = 'guardian.driver.session';

  final SecretStore _secrets;

  Future<Session?> read() async {
    final raw = await _secrets.read(_secretName);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return Session.fromJson(decoded);
    } on FormatException {
      // Unreadable stored session — a partial write, or a format from an older build. Treated
      // as signed out rather than crashing the app on launch, which on a driver handset at
      // 6:30 AM is the difference between a sign-in and a bus that cannot record boarding.
      return null;
    }
  }

  Future<void> write(Session session) =>
      _secrets.write(_secretName, jsonEncode(session.toJson()));

  Future<void> clear() => _secrets.delete(_secretName);
}
