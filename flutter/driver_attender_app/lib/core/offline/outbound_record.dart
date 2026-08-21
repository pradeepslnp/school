import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../domain.dart';
import '../time/clock_skew.dart';

/// What kind of safety record this is, and where it goes.
///
/// The endpoint is a property of the kind rather than something the caller passes, so a
/// feature enqueues "a boarding event" and cannot accidentally post one to the wrong path.
/// Contracts: [`TRIPS_BOARDING_API.md`].
///
/// Only kinds whose payload is self-contained given a trip id are listed. Anything that
/// references a *server-assigned* id — a correction pointing at the boarding event it
/// corrects, a handover pointing at an alight event — is expressible through
/// [OutboundRecord.dependsOn] and needs no new kind machinery, but the feature that enqueues
/// it must set that field. See [OutboundRecord.dependsOn].
enum OutboundKind {
  /// `POST /trips/{tripId}/boarding-events` — BRD-001…004.
  boardingEvent(
    pathTemplate: '/trips/{tripId}/boarding-events',
    batchPathTemplate: '/trips/{tripId}/boarding-events/batch',
  ),

  /// `POST /trips/{tripId}/boarding-events/{eventId}/corrections` — BRD-005.
  ///
  /// A correction is a **new** record pointing at the original; the original is never
  /// altered (BR-BOARD-001). Its path carries the corrected event's server id, so a record
  /// of this kind must declare the boarding event it depends on.
  boardingCorrection(
    pathTemplate: '/trips/{tripId}/boarding-events/{dependency}/corrections',
  ),

  /// `POST /trips/{tripId}/handovers` — BRD-008, BRD-009.
  handover(pathTemplate: '/trips/{tripId}/handovers'),

  /// `POST /trips/{tripId}/handover-exceptions` — BRD-012, the no-receiver path.
  handoverException(pathTemplate: '/trips/{tripId}/handover-exceptions'),

  /// `POST /trips/{tripId}/start` — TRP-002.
  tripStart(pathTemplate: '/trips/{tripId}/start'),

  /// `POST /trips/{tripId}/end` — TRP-004.
  tripEnd(pathTemplate: '/trips/{tripId}/end'),

  /// `POST /trips/{tripId}/close` — TRP-008, BR-SAFE-001.
  tripClose(pathTemplate: '/trips/{tripId}/close'),

  /// `POST /trips/{tripId}/manifest/amendments` — TRP-006.
  manifestAmendment(pathTemplate: '/trips/{tripId}/manifest/amendments');

  const OutboundKind({required this.pathTemplate, this.batchPathTemplate});

  final String pathTemplate;

  /// Set only where the API offers a batch endpoint.
  ///
  /// Boarding is the one that needs it: a stop produces a dozen records in under two
  /// minutes, and posting them one at a time over a recovering mobile link turns a
  /// two-second drain into a thirty-second one.
  final String? batchPathTemplate;

  bool get supportsBatch => batchPathTemplate != null;
}

/// Where a queued record stands.
enum OutboundStatus {
  /// Written locally, waiting to be sent.
  pending,

  /// Claimed by a drain pass and currently in flight.
  ///
  /// Reset to [pending] when the store is opened: a record left in flight means the app died
  /// mid-request, and whether the server received it is unknowable from here. Resending is
  /// the safe choice precisely because every record carries a client-generated id the server
  /// deduplicates on (BR-BOARD-009) — so the worst case of a wrong guess is a no-op, whereas
  /// abandoning it loses a safety record.
  inFlight,

  /// Acknowledged by the server. Kept briefly for the sync history, then prunable.
  sent,

  /// Accepted by the server but contradicting its state — needs a human.
  ///
  /// The server's own answer for these is `FLAGGED_FOR_REVIEW`, never a rejection
  /// (BR-SAFE-005): losing a real safety record is worse than storing a questionable one.
  /// The client mirrors that policy for its own refusals, so nothing is ever dropped on the
  /// device either.
  flaggedForReview,

  /// Refused for a reason repeating the request cannot fix.
  ///
  /// **Still retained.** A refused boarding record is evidence that someone tried to record
  /// a child at a stop; deleting it would erase the attempt along with the refusal.
  refused;

  bool get isSettled => this != pending && this != inFlight;
}

/// One safety record, written locally and owed to the server.
///
/// Immutable. State changes produce a new instance through [copyWith], so the queue's
/// transitions are visible as values rather than mutations of a shared object.
class OutboundRecord extends Equatable {
  const OutboundRecord({
    required this.clientEventId,
    required this.kind,
    required this.tripId,
    required this.payload,
    required this.occurredAt,
    required this.createdAt,
    this.clockSkew,
    this.status = OutboundStatus.pending,
    this.attemptCount = 0,
    this.nextAttemptAt,
    this.lastErrorCode,
    this.reviewReason,
    this.serverRecordId,
    this.dependsOn,
    this.dependsOnField,
    this.settledAt,
  });

  /// Client-generated v4 UUID. The idempotency key, and the server's uniqueness guarantee
  /// (BR-BOARD-009).
  ///
  /// Generated on the device, before the record is stored, so it is stable across every
  /// retry — including retries after a crash, a reboot, or a reinstall-free week offline.
  /// Without it, an offline queue that retries would record a child as boarding twice.
  final String clientEventId;

  final OutboundKind kind;

  /// The trip this record belongs to. Every driver-app write is trip-scoped.
  final String tripId;

  /// The request body, minus the fields this class owns ([clientEventId], `occurredAt`,
  /// `clockSkewSeconds`), which are merged in at send time so a caller cannot omit them.
  final Map<String, Object?> payload;

  /// When the attendant did the thing, by the device clock (ADR-0008).
  ///
  /// Not authoritative — see [clockSkew]. Reports order by this; the server records its own
  /// `recordedAt` alongside.
  final DateTime occurredAt;

  /// The device-vs-server clock offset at the time this record was created, if one had ever
  /// been measured.
  ///
  /// Null is meaningful and is not the same as zero: it says the app had never reached the
  /// server since install, which is exactly the situation where the device clock is least
  /// trustworthy. The sync engine fills it from the current estimate at send time when it is
  /// still null, and leaves it alone when it is not — the skew that explains `occurredAt` is
  /// the one that held when the event happened, not the one measured hours later.
  final ClockSkew? clockSkew;

  final DateTime createdAt;
  final OutboundStatus status;
  final int attemptCount;

  /// Earliest device time at which this may be retried. Null means "immediately".
  final DateTime? nextAttemptAt;

  /// Why the last attempt failed. Retained on a settled record as part of the audit trail.
  final ErrorCode? lastErrorCode;

  /// The server's explanation for a [OutboundStatus.flaggedForReview] record, verbatim —
  /// e.g. "Student marked absent after manifest was cached".
  ///
  /// Shown to staff resolving the flag, not to the attendant mid-route.
  final String? reviewReason;

  /// The id the server assigned once this record was accepted.
  ///
  /// Kept because later records may need it: a correction is posted to the path of the event
  /// it corrects, and a handover names the alight event it follows.
  final String? serverRecordId;

  /// Another record that must reach the server before this one can.
  ///
  /// This is what makes an offline handover possible. On a bus with no signal, an attendant
  /// records a child alighting and then hands them to a guardian; the handover names the
  /// alight event, but that event has no server id yet — it is still sitting in this queue.
  /// Rather than block the attendant or invent an id, the handover is stored with a
  /// dependency on the alight record's [clientEventId]. The queue will not send it until the
  /// alight record comes back with a server id, then substitutes that id into
  /// [dependsOnField] (or into the path, for [OutboundKind.boardingCorrection]).
  final String? dependsOn;

  /// The payload field to fill with the dependency's [serverRecordId] — e.g.
  /// `boardingEventId` on a handover. Null when the dependency belongs in the path instead.
  final String? dependsOnField;

  final DateTime? settledAt;

  /// Whether this record may be attempted at [now].
  bool isDueAt(DateTime now) =>
      status == OutboundStatus.pending &&
      (nextAttemptAt == null || !nextAttemptAt!.isAfter(now));

  OutboundRecord copyWith({
    ClockSkew? clockSkew,
    OutboundStatus? status,
    int? attemptCount,
    DateTime? nextAttemptAt,
    bool clearNextAttemptAt = false,
    ErrorCode? lastErrorCode,
    String? reviewReason,
    String? serverRecordId,
    DateTime? settledAt,
  }) {
    return OutboundRecord(
      clientEventId: clientEventId,
      kind: kind,
      tripId: tripId,
      payload: payload,
      occurredAt: occurredAt,
      createdAt: createdAt,
      clockSkew: clockSkew ?? this.clockSkew,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt:
          clearNextAttemptAt ? null : (nextAttemptAt ?? this.nextAttemptAt),
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      reviewReason: reviewReason ?? this.reviewReason,
      serverRecordId: serverRecordId ?? this.serverRecordId,
      dependsOn: dependsOn,
      dependsOnField: dependsOnField,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  // --- persistence ------------------------------------------------------------------------

  Map<String, Object?> toRow() => {
        'client_event_id': clientEventId,
        'kind': kind.name,
        'trip_id': tripId,
        'payload': jsonEncode(payload),
        'occurred_at': occurredAt.toIso8601String(),
        'clock_skew_seconds': clockSkew?.seconds,
        'clock_skew_measured_at': clockSkew?.measuredAt.toIso8601String(),
        'clock_skew_uncertainty_seconds': clockSkew?.uncertaintySeconds,
        'status': status.name,
        'attempt_count': attemptCount,
        'next_attempt_at': nextAttemptAt?.toIso8601String(),
        'last_error_code': lastErrorCode?.name,
        'review_reason': reviewReason,
        'server_record_id': serverRecordId,
        'depends_on_client_event_id': dependsOn,
        'depends_on_field': dependsOnField,
        'created_at': createdAt.toIso8601String(),
        'settled_at': settledAt?.toIso8601String(),
      };

  static OutboundRecord fromRow(Map<String, Object?> row) {
    final skewSeconds = row['clock_skew_seconds'] as int?;
    final skewMeasuredAt = row['clock_skew_measured_at'] as String?;

    return OutboundRecord(
      clientEventId: row['client_event_id']! as String,
      // An unrecognised kind can only come from a downgrade, which the database refuses
      // outright — so this falls back rather than throwing, and the record stays visible in
      // the queue instead of poisoning every read of the table.
      kind: OutboundKind.values.firstWhere(
        (candidate) => candidate.name == row['kind'],
        orElse: () => OutboundKind.boardingEvent,
      ),
      tripId: row['trip_id']! as String,
      payload: (jsonDecode(row['payload']! as String) as Map).cast<String, Object?>(),
      occurredAt: DateTime.parse(row['occurred_at']! as String).toUtc(),
      clockSkew: skewSeconds == null || skewMeasuredAt == null
          ? null
          : ClockSkew(
              seconds: skewSeconds,
              measuredAt: DateTime.parse(skewMeasuredAt).toUtc(),
              uncertaintySeconds:
                  row['clock_skew_uncertainty_seconds'] as int? ?? 0,
            ),
      status: OutboundStatus.values.firstWhere(
        (candidate) => candidate.name == row['status'],
        orElse: () => OutboundStatus.pending,
      ),
      attemptCount: row['attempt_count'] as int? ?? 0,
      nextAttemptAt: _parseNullable(row['next_attempt_at']),
      lastErrorCode: row['last_error_code'] == null
          ? null
          : ErrorCode.values.firstWhere(
              (candidate) => candidate.name == row['last_error_code'],
              orElse: () => ErrorCode.unknown,
            ),
      reviewReason: row['review_reason'] as String?,
      serverRecordId: row['server_record_id'] as String?,
      dependsOn: row['depends_on_client_event_id'] as String?,
      dependsOnField: row['depends_on_field'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
      settledAt: _parseNullable(row['settled_at']),
    );
  }

  static DateTime? _parseNullable(Object? raw) =>
      raw is String ? DateTime.parse(raw).toUtc() : null;

  @override
  List<Object?> get props => [
        clientEventId,
        kind,
        tripId,
        payload,
        occurredAt,
        status,
        attemptCount,
        nextAttemptAt,
        lastErrorCode,
        reviewReason,
        serverRecordId,
        dependsOn,
        dependsOnField,
        createdAt,
        settledAt,
      ];
}
