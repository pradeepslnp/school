import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small-secret storage: the database key and the session tokens.
///
/// An interface rather than a direct call to the plugin, for two reasons. It keeps the
/// platform channel behind one seam that a test can replace without a widget binding, and it
/// makes the set of things this app puts in the keychain enumerable — which matters, because
/// the wipe-on-logout guarantee in ADR-0008 is only as good as the list of things that get
/// wiped.
abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// Removes every secret this app owns.
  ///
  /// Called on logout and on remote session revocation. Deliberately not selective: a
  /// forgotten key here is a shared driver handset retaining a previous shift's access to
  /// child data.
  Future<void> deleteAll();
}

/// Keychain (iOS) and Keystore-backed storage (Android).
///
/// Constructed with the plugin's defaults. Platform options are **not** set here on purpose:
/// they vary between major versions of `flutter_secure_storage`, and a stale option copied
/// from an older release is the kind of thing that silently downgrades storage from the
/// Keystore to plain preferences. Review the installed version's README when the dependency
/// is first resolved, and set options here deliberately if that version needs them.
final class PlatformSecretStore implements SecretStore {
  PlatformSecretStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
