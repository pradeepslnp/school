import '../domain.dart';
import '../network/api_response.dart';
import '../network/rest_client.dart';
import '../time/clock.dart';
import '../time/clock_skew.dart';
import 'outbound_queue.dart';
import 'outbound_record.dart';

/// What one send attempt produced.
class TransportOutcome {
  const TransportOutcome({
    required this.settled,
    required this.reachedServer,
    this.measuredSkew,
    this.sessionEnded = false,
  });

  /// Every record from the attempt, each carrying its new status.
  final List<OutboundRecord> settled;

  /// Whether the request reached the server at all — the app's real online signal.
  final bool reachedServer;

  /// A fresh skew estimate, when the reply carried a usable server time.
  final ClockSkew? measuredSkew;

  /// The server says this session is over. The engine stops draining; retrying with a dead
  /// token would only burn battery and lock the account.
  final bool sessionEnded;
}

/// Sends queued records to the API.
///
/// Sits between the queue and [RestClient]: it knows which endpoint a record kind goes to
/// and how to read the reply, and nothing else. Deciding what a failure *means* for the
/// queue is [statusForRefusal]'s job, and deciding *when* to send is the engine's.
class OutboundTransport {
  OutboundTransport({
    required RestClient client,
    required Clock clock,
    ClockSkewEstimator? skewEstimator,
  })  : _client = client,
        _clock = clock,
        _skew = skewEstimator ?? ClockSkewEstimator(clock: clock);

  final RestClient _client;
  final Clock _clock;
  final ClockSkewEstimator _skew;

  /// Sends [records], which must share a [OutboundKind] and trip.
  ///
  /// Grouping is the caller's job because the batch endpoint is per trip. [currentSkew] fills
  /// the skew on records that never got one — see [OutboundRecord.clockSkew].
  Future<TransportOutcome> send(
    List<OutboundRecord> records, {
    ClockSkew? currentSkew,
    Map<String, String> resolvedDependencies = const {},
  }) async {
    if (records.isEmpty) {
      return const TransportOutcome(settled: [], reachedServer: true);
    }

    final kind = records.first.kind;
    final useBatch = kind.supportsBatch && records.length > 1;

    return useBatch
        ? _sendBatch(records, currentSkew, resolvedDependencies)
        : _sendIndividually(records, currentSkew, resolvedDependencies);
  }

  // --- batch ------------------------------------------------------------------------------

  Future<TransportOutcome> _sendBatch(
    List<OutboundRecord> records,
    ClockSkew? currentSkew,
    Map<String, String> resolvedDependencies,
  ) async {
    final first = records.first;
    final path = _path(
      first.kind.batchPathTemplate!,
      tripId: first.tripId,
      dependencyId: null,
    );

    final response = await _client.post(
      path,
      body: {
        'events': [
          for (final record in records)
            _body(record, currentSkew, resolvedDependencies),
        ],
      },
      // The batch is safe to repeat: every event inside it carries its own client id, and
      // the server deduplicates on that (BR-BOARD-009). Without a key here, RestClient would
      // refuse to retry a POST at all — correctly, since an unkeyed retry of a boarding
      // batch would double-record a busload of children.
      idempotencyKey: _batchKey(records),
    );

    final skew = _measure(response);

    if (response.isTransportFailure) {
      return TransportOutcome(
        settled: [for (final r in records) _retry(r, ErrorCode.dependencyUnavailable)],
        reachedServer: false,
      );
    }

    if (response.isUnauthorized) {
      return TransportOutcome(
        settled: [for (final r in records) _retry(r, ErrorCode.authTokenExpired)],
        reachedServer: true,
        measuredSkew: skew,
        sessionEnded: ErrorCode.fromWire(response.errorCode).endsSession,
      );
    }

    // `202` with per-event results: each event is processed independently, and one rejection
    // never discards the batch (TRIPS_BOARDING_API.md).
    if (!response.isSuccess) {
      // A whole-batch refusal — malformed envelope, trip not found, permission. The records
      // themselves were never judged, so they are settled from the batch-level code rather
      // than guessed at individually.
      final code = ErrorCode.fromWire(response.errorCode);
      return TransportOutcome(
        settled: [
          for (final record in records)
            _settleWith(record, code, response.errorMessageKey),
        ],
        reachedServer: true,
        measuredSkew: skew,
      );
    }

    final results = <String, Map<String, Object?>>{};
    for (final entry in response.data['results'] as List<Object?>? ?? const []) {
      if (entry is! Map) continue;
      final id = entry['clientEventId'];
      if (id is String) results[id] = entry.cast<String, Object?>();
    }

    return TransportOutcome(
      settled: [
        for (final record in records)
          _applyBatchResult(record, results[record.clientEventId]),
      ],
      reachedServer: true,
      measuredSkew: skew,
    );
  }

  OutboundRecord _applyBatchResult(
    OutboundRecord record,
    Map<String, Object?>? result,
  ) {
    // An event missing from the results array was neither accepted nor refused. It is put
    // back rather than assumed sent: assuming success here would silently drop a boarding
    // record, which is the one outcome this whole subsystem exists to prevent.
    if (result == null) return _retry(record, ErrorCode.internalError);

    final now = _clock.nowUtc();

    return switch (result['status']) {
      // DUPLICATE is a success. It means an earlier attempt did reach the server — the
      // normal outcome when a reply was lost on a fading link — and the idempotency key did
      // its job.
      'CREATED' || 'DUPLICATE' => record.copyWith(
          status: OutboundStatus.sent,
          serverRecordId: result['eventId'] as String?,
          settledAt: now,
          clearNextAttemptAt: true,
        ),
      'FLAGGED_FOR_REVIEW' => record.copyWith(
          status: OutboundStatus.flaggedForReview,
          serverRecordId: result['eventId'] as String?,
          reviewReason: result['reason'] as String?,
          settledAt: now,
          clearNextAttemptAt: true,
        ),
      // Any other status, including one added to the API after this build shipped. It is
      // settled as a refusal rather than guessed at, which keeps the record and puts it in
      // front of a person — the safe direction for a status this app cannot interpret.
      _ => _settleWith(
          record,
          ErrorCode.fromWire(result['code'] as String?),
          result['messageKey'] as String?,
        ),
    };
  }

  // --- single -----------------------------------------------------------------------------

  Future<TransportOutcome> _sendIndividually(
    List<OutboundRecord> records,
    ClockSkew? currentSkew,
    Map<String, String> resolvedDependencies,
  ) async {
    final settled = <OutboundRecord>[];
    ClockSkew? skew;
    var reachedServer = true;
    var sessionEnded = false;

    for (final record in records) {
      final path = _path(
        record.kind.pathTemplate,
        tripId: record.tripId,
        dependencyId: record.dependsOn == null
            ? null
            : resolvedDependencies[record.dependsOn],
      );

      final response = await _client.post(
        path,
        body: _body(record, currentSkew, resolvedDependencies),
        // The client id is the idempotency key. This is what makes the whole offline queue
        // safe to retry: the server returns the original record rather than creating a
        // second one (BR-BOARD-009).
        idempotencyKey: record.clientEventId,
      );

      skew = _measure(response) ?? skew;

      if (response.isTransportFailure) {
        settled.add(_retry(record, ErrorCode.dependencyUnavailable));
        reachedServer = false;
        // Stop on the first unreachable send. The rest of the batch would fail the same way,
        // and every extra attempt is radio time on a vehicle.
        settled.addAll(
          records
              .skip(settled.length)
              .map((r) => _retry(r, ErrorCode.dependencyUnavailable)),
        );
        break;
      }

      if (response.isUnauthorized) {
        final code = ErrorCode.fromWire(response.errorCode);
        sessionEnded = code.endsSession;
        settled.add(_retry(record, ErrorCode.authTokenExpired));
        settled.addAll(
          records
              .skip(settled.length)
              .map((r) => _retry(r, ErrorCode.authTokenExpired)),
        );
        break;
      }

      if (response.isSuccess) {
        settled.add(
          record.copyWith(
            status: OutboundStatus.sent,
            serverRecordId: response.data['id'] as String?,
            settledAt: _clock.nowUtc(),
            clearNextAttemptAt: true,
          ),
        );
        continue;
      }

      settled.add(
        _settleWith(
          record,
          ErrorCode.fromWire(response.errorCode),
          response.errorMessageKey,
        ),
      );
    }

    return TransportOutcome(
      settled: settled,
      reachedServer: reachedServer,
      measuredSkew: skew,
      sessionEnded: sessionEnded,
    );
  }

  // --- shared -----------------------------------------------------------------------------

  /// The request body: the caller's payload plus the fields ADR-0008 requires on every
  /// record, merged here so no feature can forget one.
  Map<String, Object?> _body(
    OutboundRecord record,
    ClockSkew? currentSkew,
    Map<String, String> resolvedDependencies,
  ) {
    final skew = record.clockSkew ?? currentSkew;
    final dependency = record.dependsOn;
    final dependencyField = record.dependsOnField;
    final dependencyId =
        dependency == null ? null : resolvedDependencies[dependency];

    return {
      ...record.payload,
      'clientEventId': record.clientEventId,
      'occurredAt': record.occurredAt.toIso8601String(),
      if (skew != null) 'clockSkewSeconds': skew.seconds,
      if (dependencyField != null && dependencyId != null)
        dependencyField: dependencyId,
    };
  }

  String _path(
    String template, {
    required String tripId,
    required String? dependencyId,
  }) {
    return template
        .replaceAll('{tripId}', tripId)
        .replaceAll('{dependency}', dependencyId ?? '');
  }

  /// A stable key for a batch, so retrying the batch itself is safe.
  ///
  /// Derived from the member ids rather than generated per attempt — a fresh key on each
  /// retry would tell the server this is a different batch, defeating the point.
  String _batchKey(List<OutboundRecord> records) {
    final ids = records.map((record) => record.clientEventId).toList()..sort();
    return 'batch:${ids.join(',')}'.hashCode.toRadixString(16);
  }

  ClockSkew? _measure(ApiResponse response) {
    final sentAt = response.sentAt;
    final receivedAt = response.receivedAt;
    if (sentAt == null || receivedAt == null) return null;

    final meta = response.body['meta'] as Map<String, Object?>?;

    return _skew.measure(
      responseHeaders: response.headers,
      sentAt: sentAt,
      receivedAt: receivedAt,
      envelopeTimestamp: meta?['timestamp'] as String?,
    );
  }

  OutboundRecord _retry(OutboundRecord record, ErrorCode code) {
    final attempts = record.attemptCount + 1;
    return record.copyWith(
      status: OutboundStatus.pending,
      attemptCount: attempts,
      nextAttemptAt: _clock.nowUtc().add(retryDelayFor(attempts)),
      lastErrorCode: code,
    );
  }

  OutboundRecord _settleWith(
    OutboundRecord record,
    ErrorCode code,
    String? messageKey,
  ) {
    final status = statusForRefusal(code);

    if (status == OutboundStatus.pending) {
      return _retry(record, code);
    }

    return record.copyWith(
      status: status,
      attemptCount: record.attemptCount + 1,
      lastErrorCode: code,
      reviewReason: messageKey,
      settledAt: _clock.nowUtc(),
      clearNextAttemptAt: true,
    );
  }
}
