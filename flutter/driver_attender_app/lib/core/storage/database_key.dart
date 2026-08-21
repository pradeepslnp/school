import 'dart:convert';
import 'dart:math';

import 'secret_store.dart';

/// The SQLCipher passphrase for the local store.
///
/// Generated on the device on first use and never transmitted. It is not derived from
/// anything the user knows: a driver signs in with a phone number and a six-digit OTP, and a
/// key derived from those would be trivially reproducible by anyone holding the handset.
///
/// The key lives in the platform keychain, so the encrypted database on disk is useless
/// without the hardware-backed store that holds it — which is the property that matters when
/// a shared driver handset is lost with a day of child data on it (ADR-0008).
class DatabaseKey {
  DatabaseKey({required SecretStore secrets, Random? random})
      : _secrets = secrets,
        _random = random ?? Random.secure();

  /// Keychain entry name. Changing this orphans existing databases, which then cannot be
  /// opened — treat it as part of the storage contract, not a label.
  static const String secretName = 'guardian.driver.localStoreKey';

  static const int _keyLengthBytes = 32;

  final SecretStore _secrets;
  final Random _random;

  /// The existing key, or a newly generated one.
  ///
  /// Generation is a side effect of the first read on purpose: there is no separate
  /// "provision" step that could be skipped by a code path that opens the database directly.
  Future<String> obtain() async {
    final existing = await _secrets.read(secretName);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generate();
    await _secrets.write(secretName, generated);
    return generated;
  }

  /// Discards the key.
  ///
  /// Called as part of the logout wipe. Destroying the key does not by itself erase the
  /// database file, so callers must delete the file too — [LocalDatabase.wipe] does both, in
  /// that order, so an interrupted wipe leaves unreadable ciphertext rather than a readable
  /// database.
  Future<void> destroy() => _secrets.delete(secretName);

  String _generate() {
    // Random.secure() is the platform CSPRNG. A non-secure Random here would make the key
    // predictable from the seed, and the encryption decorative.
    final bytes = List<int>.generate(
      _keyLengthBytes,
      (_) => _random.nextInt(256),
      growable: false,
    );
    return base64UrlEncode(bytes);
  }
}
