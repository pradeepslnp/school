import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'database_key.dart';

/// The encrypted local store — the driver app's **primary write target** (ADR-0008).
///
/// Not a cache. A boarding event is written here first and acknowledged in the UI
/// immediately; sending it to the server happens afterwards, from a queue, possibly minutes
/// later when the vehicle regains coverage. The server is the eventual system of record; for
/// the length of a coverage gap, this file is the only copy of what happened on that bus.
///
/// Two consequences follow, and both are load-bearing:
///
/// * **Encrypted.** The contents are child PII on a handset that changes hands between
///   shifts. SQLCipher, keyed from the platform keychain ([DatabaseKey]).
/// * **Never dropped to migrate.** A schema migration that recreates the store would delete
///   unsynced safety records — a class of data loss the platform exists to prevent. Every
///   migration is forward-only and additive; see [_migrate].
class LocalDatabase {
  LocalDatabase({
    required DatabaseKey key,
    this.fileName = 'guardian_driver.db',
  }) : _key = key;

  /// Bumped for every schema change, with a matching step in [_migrate].
  static const int schemaVersion = 1;

  final DatabaseKey _key;
  final String fileName;

  Database? _database;

  /// The open database, opening it if necessary.
  ///
  /// Idempotent, so callers do not coordinate. Concurrent first calls are possible during
  /// startup; the assignment is not awaited between the check and the open, so the future is
  /// cached rather than the database.
  Future<Database> open() async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    final opening = _opening ??= _openInternal();
    try {
      return await opening;
    } finally {
      _opening = null;
    }
  }

  Future<Database>? _opening;

  Future<Database> _openInternal() async {
    final path = p.join(await getDatabasesPath(), fileName);
    final password = await _key.obtain();

    final database = await openDatabase(
      path,
      password: password,
      version: schemaVersion,
      onCreate: (db, version) => _migrate(db, 0, version),
      onUpgrade: _migrate,
      onConfigure: (db) async {
        // Foreign keys are off by default in SQLite. Nothing here relies on them yet, but a
        // constraint that is only sometimes enforced is worse than none.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      // onDowngrade is deliberately left at the default, which fails.
      //
      // sqflite offers `onDowngradeDeleteDatabase`, and it must never be used here: it would
      // silently delete every unsynced boarding record the moment a driver's handset was
      // rolled back to an older build. Failing loudly is the safe direction.
    );

    _database = database;
    return database;
  }

  /// Applies every migration step between [from] and [to].
  ///
  /// Written as a fall-through switch rather than one block per version pair, so a device
  /// that skipped three releases takes the same path as one that skipped none.
  static Future<void> _migrate(Database db, int from, int to) async {
    if (from < 1) {
      // The outbound queue: safety records written locally and not yet acknowledged by the
      // server.
      await db.execute('''
        CREATE TABLE outbound_records (
          client_event_id                TEXT PRIMARY KEY NOT NULL,
          kind                           TEXT NOT NULL,
          trip_id                        TEXT,
          payload                        TEXT NOT NULL,
          occurred_at                    TEXT NOT NULL,
          clock_skew_seconds             INTEGER,
          clock_skew_measured_at         TEXT,
          clock_skew_uncertainty_seconds INTEGER,
          status                         TEXT NOT NULL,
          attempt_count                  INTEGER NOT NULL DEFAULT 0,
          next_attempt_at                TEXT,
          last_error_code                TEXT,
          review_reason                  TEXT,
          server_record_id               TEXT,
          depends_on_client_event_id     TEXT,
          depends_on_field               TEXT,
          created_at                     TEXT NOT NULL,
          settled_at                     TEXT
        )
      ''');

      // `client_event_id` is the PRIMARY KEY rather than a generated rowid, so a record
      // cannot be enqueued twice under the same identity even by a caller that retries
      // (BR-BOARD-009). The idempotency guarantee starts on the device, not at the API.

      // The drain query is "everything pending and due, oldest first".
      await db.execute('''
        CREATE INDEX idx_outbound_due
        ON outbound_records (status, next_attempt_at, created_at)
      ''');

      // Small, durable key/value state that must survive a restart alongside the queue:
      // the clock-skew estimate and the last successful sync time.
      await db.execute('''
        CREATE TABLE sync_metadata (
          key   TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL
        )
      ''');
    }

    // Later versions add their steps here, each guarded by `if (from < n)`. Steps are
    // additive: add a column, backfill it, add an index. A step that drops or rewrites a
    // column holding safety data needs its own ADR.
  }

  /// Closes the database without destroying anything.
  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  /// Destroys the local store and its key.
  ///
  /// Called on logout and on remote session revocation (ADR-0008, AUTHENTICATION_API.md
  /// §logout). **This deletes unsynced records**, which is correct and deliberate: a driver
  /// signing off a shared handset must not leave a queue of another shift's child data on it,
  /// and the alternative — retaining PII on a device now in someone else's hands — is worse.
  /// Callers should drain the queue first where they can; see `SyncEngine.drain`.
  ///
  /// The key is destroyed **before** the file is removed. If the process dies between the
  /// two, what remains on disk is ciphertext no longer openable by anything — the safe
  /// failure. Doing it the other way round would leave a window with a readable database and
  /// a live key.
  Future<void> wipe() async {
    await close();
    await _key.destroy();

    final path = p.join(await getDatabasesPath(), fileName);
    await deleteDatabase(path);
  }
}
