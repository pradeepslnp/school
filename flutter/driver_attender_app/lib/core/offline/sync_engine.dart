import 'dart:async';

import '../time/clock.dart';
import '../time/clock_skew.dart';
import 'outbound_queue.dart';
import 'outbound_record.dart';
import 'outbound_transport.dart';
import 'sync_metadata.dart';
import 'sync_status.dart';

/// Drains the outbound queue in the background.
///
/// The contract with the rest of the app is narrow on purpose: features write to the queue
/// and never speak to this class. Nothing here is on the path of a safety action — an
/// attendant marking a child boarded is not waiting on any of it (ADR-0008).
///
/// Draining is **single-flight**. Two concurrent drains would claim overlapping records and
/// send the same boarding event twice; the queue's claim transaction guards that too, and
/// both guards are kept because the cost of being wrong is a duplicated child record.
class SyncEngine {
  SyncEngine({
    required OutboundQueue queue,
    required OutboundTransport transport,
    required SyncMetadata metadata,
    required Clock clock,
    this.pollInterval = const Duration(seconds: 30),
    this.batchSize = 50,
    Future<void> Function()? onSessionEnded,
  })  : _queue = queue,
        _transport = transport,
        _metadata = metadata,
        _clock = clock,
        _onSessionEnded = onSessionEnded;

  /// How often to try the queue when nothing else prompts it.
  ///
  /// A timer rather than a connectivity callback: this app treats "can I reach the API" as
  /// the only meaningful online signal, and the way to learn that is to try
  /// (see [Reachability]). Thirty seconds is a compromise between a vehicle that regained
  /// signal a moment ago and one that has been in a dead zone for twenty minutes with the
  /// radio scanning.
  final Duration pollInterval;

  final int batchSize;

  final OutboundQueue _queue;
  final OutboundTransport _transport;
  final SyncMetadata _metadata;
  final Clock _clock;

  /// Invoked when the server says the session is over — a revoked session, or refresh reuse
  /// (BR-IAM-007, BR-IAM-009). Wired to the sign-out path, which wipes the local store.
  final Future<void> Function()? _onSessionEnded;

  final StreamController<SyncStatus> _status =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _current = const SyncStatus();
  ClockSkew? _clockSkew;
  Timer? _timer;
  Future<void>? _inProgress;
  StreamSubscription<QueueCounts>? _queueSubscription;

  /// The current view of the queue, for a widget that needs a value before the first event.
  SyncStatus get status => _current;

  Stream<SyncStatus> get statusStream => _status.stream;

  /// The latest device-vs-server clock offset, or null if never measured.
  ///
  /// Read by whatever enqueues a record, so the estimate is stamped on it at creation time
  /// rather than at send time — the skew that explains when an event happened is the one
  /// that held when it happened.
  ClockSkew? get clockSkew => _clockSkew;

  /// Recovers state left by the previous run and begins draining.
  Future<void> start() async {
    // Anything still marked in flight belongs to a process that died mid-request. Safe to
    // resend: the server deduplicates on the client id.
    await _queue.releaseInFlight();

    _clockSkew = await _metadata.readClockSkew();

    _emit(
      _current.copyWith(
        lastSyncedAt: await _metadata.readLastSyncedAt(),
      ),
    );

    _queueSubscription = _queue.watch().listen(_onQueueChanged);
    await _refreshCounts();

    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => unawaited(drain()));

    unawaited(drain());
  }

  /// Sends everything currently due.
  ///
  /// Safe to call from anywhere and as often as anything likes — a call made while a drain
  /// is running joins that drain rather than starting a second one.
  Future<void> drain() {
    return _inProgress ??= _drain().whenComplete(() => _inProgress = null);
  }

  Future<void> _drain() async {
    _emit(_current.copyWith(isSyncing: true));

    try {
      // Before claiming anything, retire dependents that can never be sent. Left alone they
      // would count as pending forever, and a pending count that never falls is how an
      // attendant learns to stop believing the indicator.
      await _queue.flagUnsatisfiableDependents();

      while (true) {
        final claimed =
            await _queue.claimDue(now: _clock.nowUtc(), limit: batchSize);
        if (claimed.isEmpty) break;

        final dependencies = await _resolveDependencies(claimed);
        var interrupted = false;

        for (final group in _groupForSending(claimed)) {
          final outcome = await _transport.send(
            group,
            currentSkew: _clockSkew,
            resolvedDependencies: dependencies,
          );

          for (final record in outcome.settled) {
            await _queue.settle(record);
          }

          final measured = outcome.measuredSkew;
          if (measured != null) {
            _clockSkew = measured;
            await _metadata.writeClockSkew(measured);
          }

          _emit(
            _current.copyWith(
              reachability: outcome.reachedServer
                  ? Reachability.reachable
                  : Reachability.unreachable,
            ),
          );

          if (outcome.sessionEnded) {
            // Nothing else will succeed, and repeated calls with a dead token are how an
            // account gets locked. Hand off and stop.
            await _onSessionEnded?.call();
            interrupted = true;
            break;
          }

          if (!outcome.reachedServer) {
            interrupted = true;
            break;
          }
        }

        if (interrupted) break;
      }

      final counts = await _queue.counts();
      if (counts.outstanding == 0 &&
          _current.reachability == Reachability.reachable) {
        final now = _clock.nowUtc();
        await _metadata.writeLastSyncedAt(now);
        _emit(_current.copyWith(lastSyncedAt: now));
      }
    } finally {
      _emit(_current.copyWith(isSyncing: false));
      await _refreshCounts();
    }
  }

  /// Looks up the server ids of records other records are waiting on.
  ///
  /// A handover recorded offline names the alight event it follows, but that event may only
  /// have been acknowledged seconds ago; its server id lives on the settled record in the
  /// queue, not in the handover's payload.
  Future<Map<String, String>> _resolveDependencies(
    List<OutboundRecord> records,
  ) async {
    final resolved = <String, String>{};
    for (final record in records) {
      final dependency = record.dependsOn;
      if (dependency == null || resolved.containsKey(dependency)) continue;
      final found = await _queue.find(dependency);
      final serverId = found?.serverRecordId;
      if (serverId != null) resolved[dependency] = serverId;
    }
    return resolved;
  }

  /// Splits a claim into runs that can go in one request.
  ///
  /// Records are grouped by kind and trip because that is what the batch endpoint accepts,
  /// and **order within a trip is preserved**: boarding events for one child must reach the
  /// server in the order they happened, or an alight can arrive before its board and be
  /// refused as `BOARDING_NOT_BOARDED`.
  List<List<OutboundRecord>> _groupForSending(List<OutboundRecord> records) {
    final groups = <String, List<OutboundRecord>>{};
    for (final record in records) {
      groups
          .putIfAbsent('${record.kind.name}:${record.tripId}', () => [])
          .add(record);
    }
    return groups.values.toList(growable: false);
  }

  void _onQueueChanged(QueueCounts counts) => _emit(_fromCounts(counts));

  Future<void> _refreshCounts() async => _emit(_fromCounts(await _queue.counts()));

  SyncStatus _fromCounts(QueueCounts counts) => _current.copyWith(
        pendingCount: counts.outstanding,
        flaggedForReviewCount: counts.flaggedForReview,
        refusedCount: counts.refused,
      );

  void _emit(SyncStatus status) {
    if (status == _current) return;
    _current = status;
    if (!_status.isClosed) _status.add(status);
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _queueSubscription?.cancel();
    _queueSubscription = null;
    await _status.close();
  }
}
