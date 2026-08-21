import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../storage/local_database.dart';
import '../time/clock_skew.dart';

/// Durable state the sync engine needs across restarts.
///
/// Small enough to be a key/value table, and deliberately in the **encrypted** store rather
/// than shared preferences: the clock-skew estimate is part of the provenance of every
/// safety record written on this device, and it should not be sitting somewhere another app
/// or an adb pull can rewrite.
class SyncMetadata {
  SyncMetadata({required LocalDatabase database}) : _database = database;

  static const String _table = 'sync_metadata';
  static const String _skewKey = 'clockSkew';
  static const String _lastSyncedAtKey = 'lastSyncedAt';

  final LocalDatabase _database;

  Future<ClockSkew?> readClockSkew() async {
    final raw = await _read(_skewKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? ClockSkew.fromJson(decoded) : null;
  }

  Future<void> writeClockSkew(ClockSkew skew) =>
      _write(_skewKey, jsonEncode(skew.toJson()));

  /// When the queue was last drained empty.
  ///
  /// "Last synced" in the banner means *nothing was left owing*, not "a request succeeded" —
  /// the second would let the indicator read as clear while records were still queued.
  Future<DateTime?> readLastSyncedAt() async {
    final raw = await _read(_lastSyncedAtKey);
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> writeLastSyncedAt(DateTime at) =>
      _write(_lastSyncedAtKey, at.toUtc().toIso8601String());

  Future<String?> _read(String key) async {
    final db = await _database.open();
    final rows = await db.query(
      _table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> _write(String key, String value) async {
    final db = await _database.open();
    await db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
