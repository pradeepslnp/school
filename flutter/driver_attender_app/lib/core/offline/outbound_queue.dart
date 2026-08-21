import 'dart:async';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain.dart';
import '../storage/local_database.dart';
import '../time/clock.dart';
import '../time/clock_skew.dart';
import 'outbound_record.dart';
import 'sync_status.dart';

/// The durable queue of safety records owed to the server.
///
/// An interface so features depend on the behaviour, not on SQLite, and so a bloc test can
/// run against an in-memory implementation with no plugin binding.
abstract interface class OutboundQueue {
  /// Stores a record and returns immediately.
  ///
  /// This is the write path for every safety action in the app. It does **not** contact the
  /// network and must not be awaited on anything that does: the UI acknowledges a boarding
  /// the moment this resolves, and a child at the door of a bus does not wait for a spinner
  /// (ADR-0008, CODING_STANDARDS_FLUTTER.md §Offline).
  Future<OutboundRecord> enqueue({
    required OutboundKind kind,
    required String tripId,
    required Map<String, Object?> payload,
    required DateTime occurredAt,
    ClockSkew? clockSkew,
    String? dependsOn,
    String? dependsOnField,
  });

  /// Takes up to [limit] records that are due and whose dependencies have been sent, and
  /// marks them in flight.
  Future<List<OutboundRecord>> claimDue({
    required DateTime now,
    int limit = 50,
  });

  /// Writes back the outcome of an attempt.
  Future<void> settle(OutboundRecord record);

  /// Returns records left in flight to [OutboundStatus.pending].
  ///
  /// Run at startup. A record still in flight means the process died mid-request; whether
  /// the server received it cannot be known from here, and resending is safe because the
  /// server deduplicates on the client id (BR-BOARD-009).
  Future<int> releaseInFlight();

  /// Moves records whose dependency can never be satisfied to
  /// [OutboundStatus.flaggedForReview], and returns how many.
  ///
  /// A dependent waits for its predecessor's server id. If the predecessor settled *without*
  /// one — accepted by a server that returned no id, or refused outright — the dependent
  /// would never become claimable and would sit in the pending count forever, looking to the
  /// attendant like a queue that will eventually clear. Surfacing it for review is the
  /// honest outcome: a handover whose alight event was refused is exactly the kind of thing
  /// a person needs to look at.
  Future<int> flagUnsatisfiableDependents();

  Future<OutboundRecord?> find(String clientEventId);

  /// Records the attendant or office still has to resolve — flagged or refused.
  Future<List<OutboundRecord>> recordsNeedingReview();

  Future<QueueCounts> counts();

  /// Emits after every change. Broadcast; the banner and any pending-records screen both
  /// listen.
  Stream<QueueCounts> watch();

  Future<void> close();
}

/// [OutboundQueue] over the encrypted local store.
class SqliteOutboundQueue implements OutboundQueue {
  SqliteOutboundQueue({
    required LocalDatabase database,
    required Clock clock,
    Uuid? uuid,
  })  : _database = database,
        _clock = clock,
        _uuid = uuid ?? const Uuid();

  static const String _table = 'outbound_records';

  final LocalDatabase _database;
  final Clock _clock;
  final Uuid _uuid;

  final StreamController<QueueCounts> _changes =
      StreamController<QueueCounts>.broadcast();

  @override
  Future<OutboundRecord> enqueue({
    required OutboundKind kind,
    required String tripId,
    required Map<String, Object?> payload,
    required DateTime occurredAt,
    ClockSkew? clockSkew,
    String? dependsOn,
    String? dependsOnField,
  }) async {
    final record = OutboundRecord(
      // v4 — random, not time-based. A v1 UUID embeds the device MAC and the device clock,
      // and this app's records are child safety data written on a clock it does not trust.
      clientEventId: _uuid.v4(),
      kind: kind,
      tripId: tripId,
      payload: payload,
      occurredAt: occurredAt.toUtc(),
      createdAt: _clock.nowUtc(),
      clockSkew: clockSkew,
      dependsOn: dependsOn,
      dependsOnField: dependsOnField,
    );

    final db = await _database.open();
    await db.insert(
      _table,
      record.toRow(),
      // The primary key is the client id, which is generated here and unique. A collision
      // would mean the generator repeated itself; failing is the honest response, because
      // replacing would silently discard a different safety record.
      conflictAlgorithm: ConflictAlgorithm.fail,
    );

    await _publish();
    return record;
  }

  @override
  Future<List<OutboundRecord>> claimDue({
    required DateTime now,
    int limit = 50,
  }) async {
    final db = await _database.open();
    final nowIso = now.toUtc().toIso8601String();

    // One transaction, so two drains cannot claim the same record. The engine is
    // single-flight as well; this is the second lock, because losing to a race here would
    // mean sending a boarding event twice.
    return db.transaction<List<OutboundRecord>>((txn) async {
      final rows = await txn.rawQuery(
        '''
        SELECT r.*
        FROM $_table r
        LEFT JOIN $_table dep
          ON dep.client_event_id = r.depends_on_client_event_id
        WHERE r.status = ?
          AND (r.next_attempt_at IS NULL OR r.next_attempt_at <= ?)
          AND (
            r.depends_on_client_event_id IS NULL
            OR dep.server_record_id IS NOT NULL
          )
        ORDER BY r.created_at ASC
        LIMIT ?
        ''',
        [OutboundStatus.pending.name, nowIso, limit],
      );

      // Oldest first, and dependencies gated: a handover recorded offline waits for the
      // alight event it names to come back with a server id, rather than being sent with a
      // missing reference or blocking the attendant who recorded it.

      if (rows.isEmpty) return const <OutboundRecord>[];

      final records = rows.map(OutboundRecord.fromRow).toList(growable: false);
      final ids = records.map((record) => record.clientEventId).toList();
      final placeholders = List.filled(ids.length, '?').join(', ');

      await txn.rawUpdate(
        'UPDATE $_table SET status = ? WHERE client_event_id IN ($placeholders)',
        [OutboundStatus.inFlight.name, ...ids],
      );

      return records
          .map((record) => record.copyWith(status: OutboundStatus.inFlight))
          .toList(growable: false);
    }).whenComplete(_publish);
  }

  @override
  Future<void> settle(OutboundRecord record) async {
    final db = await _database.open();
    await db.update(
      _table,
      record.toRow(),
      where: 'client_event_id = ?',
      whereArgs: [record.clientEventId],
    );
    await _publish();
  }

  @override
  Future<int> releaseInFlight() async {
    final db = await _database.open();
    final released = await db.update(
      _table,
      {
        'status': OutboundStatus.pending.name,
        // Cleared so recovered records go out on the next drain rather than waiting out a
        // backoff that was scheduled before the crash.
        'next_attempt_at': null,
      },
      where: 'status = ?',
      whereArgs: [OutboundStatus.inFlight.name],
    );
    if (released > 0) await _publish();
    return released;
  }

  @override
  Future<int> flagUnsatisfiableDependents() async {
    final db = await _database.open();

    final flagged = await db.rawUpdate(
      '''
      UPDATE $_table
      SET status = ?, review_reason = ?, settled_at = ?
      WHERE status = ?
        AND depends_on_client_event_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM $_table dep
          WHERE dep.client_event_id = $_table.depends_on_client_event_id
            AND dep.status IN (?, ?, ?)
            AND dep.server_record_id IS NULL
        )
      ''',
      [
        OutboundStatus.flaggedForReview.name,
        'The record this one refers to was not accepted by the server.',
        _clock.nowUtc().toIso8601String(),
        OutboundStatus.pending.name,
        OutboundStatus.sent.name,
        OutboundStatus.flaggedForReview.name,
        OutboundStatus.refused.name,
      ],
    );

    if (flagged > 0) await _publish();
    return flagged;
  }

  @override
  Future<OutboundRecord?> find(String clientEventId) async {
    final db = await _database.open();
    final rows = await db.query(
      _table,
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OutboundRecord.fromRow(rows.first);
  }

  @override
  Future<List<OutboundRecord>> recordsNeedingReview() async {
    final db = await _database.open();
    final rows = await db.query(
      _table,
      where: 'status IN (?, ?)',
      whereArgs: [
        OutboundStatus.flaggedForReview.name,
        OutboundStatus.refused.name,
      ],
      orderBy: 'occurred_at ASC',
    );
    return rows.map(OutboundRecord.fromRow).toList(growable: false);
  }

  @override
  Future<QueueCounts> counts() async {
    final db = await _database.open();
    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS total FROM $_table GROUP BY status',
    );

    var pending = 0;
    var inFlight = 0;
    var flaggedForReview = 0;
    var refused = 0;

    for (final row in rows) {
      final total = (row['total'] as int?) ?? 0;
      switch (row['status']) {
        case 'pending':
          pending = total;
        case 'inFlight':
          inFlight = total;
        case 'flaggedForReview':
          flaggedForReview = total;
        case 'refused':
          refused = total;
        // 'sent' is not counted: an acknowledged record is not outstanding work.
      }
    }

    return QueueCounts(
      pending: pending,
      inFlight: inFlight,
      flaggedForReview: flaggedForReview,
      refused: refused,
    );
  }

  @override
  Stream<QueueCounts> watch() => _changes.stream;

  @override
  Future<void> close() async {
    await _changes.close();
  }

  Future<void> _publish() async {
    if (_changes.isClosed) return;
    _changes.add(await counts());
  }
}

/// Backoff schedule for a failed send.
///
/// Exponential from 2 seconds, capped at five minutes. The cap matters more than the curve:
/// coverage gaps on a school route last minutes, and an unbounded backoff would leave a
/// vehicle that regained signal fifteen minutes ago still sitting on its queue.
Duration retryDelayFor(int attemptCount) {
  const base = Duration(seconds: 2);
  const cap = Duration(minutes: 5);
  // 1 << 8 is already past the cap; clamping the shift keeps the arithmetic in range on a
  // record that has been failing all day.
  final shift = attemptCount.clamp(0, 8);
  final delay = base * (1 << shift);
  return delay > cap ? cap : delay;
}

/// How the queue should treat a server refusal.
///
/// Nothing here deletes. The choice is only between trying again, and keeping the record
/// where a human will see it (ADR-0008: losing a real safety record is worse than storing a
/// questionable one).
OutboundStatus statusForRefusal(ErrorCode code) {
  if (code.isWorthRetrying) return OutboundStatus.pending;

  return switch (code) {
    // The server's state disagrees with what the attendant saw — the manifest changed after
    // it was cached, or the same child is on another vehicle's manifest. These are exactly
    // the cases BR-SAFE-005 says to keep and flag, not discard. `BOARDING_WRONG_VEHICLE` in
    // particular is a safety detection: the record is the evidence.
    ErrorCode.boardingStudentNotOnManifest ||
    ErrorCode.boardingWrongVehicle ||
    ErrorCode.boardingWrongStop ||
    ErrorCode.boardingAlreadyBoarded ||
    ErrorCode.boardingNotBoarded ||
    ErrorCode.tripInvalidStatusTransition ||
    ErrorCode.tripAlreadyCompleted =>
      OutboundStatus.flaggedForReview,
    _ => OutboundStatus.refused,
  };
}
