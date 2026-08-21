import 'package:equatable/equatable.dart';

/// Whether the API can actually be reached.
///
/// Derived from the outcome of real requests to our own API, not from the OS connectivity
/// flag. That flag answers "is there a network interface up", which is a different question:
/// a bus WiFi hotspot with no backhaul, a captive portal, and a cell tower that accepts an
/// attachment but routes nothing all report *connected*. An attendant told "online" while
/// twelve boarding records sit unsent has been told something false.
enum Reachability {
  /// Nothing has been attempted yet since launch.
  unknown,

  /// The last attempt reached the server, whatever the server then said.
  reachable,

  /// The last attempt did not reach the server.
  unreachable,
}

/// What the attendant is shown about the outbound queue (D-14).
///
/// Visible on **every** screen. Silent queuing hides failure from the one person positioned
/// to act on it — by keeping the app open until it clears, or by telling the office
/// (ADR-0008, DRIVER_ATTENDANT_APP.md).
class SyncStatus extends Equatable {
  const SyncStatus({
    this.reachability = Reachability.unknown,
    this.pendingCount = 0,
    this.flaggedForReviewCount = 0,
    this.refusedCount = 0,
    this.isSyncing = false,
    this.lastSyncedAt,
  });

  final Reachability reachability;

  /// Records written locally and not yet acknowledged.
  final int pendingCount;

  /// Records the server accepted but flagged as contradicting its state (BR-SAFE-005).
  final int flaggedForReviewCount;

  /// Records the server refused for a reason a retry cannot fix. Retained, not discarded.
  final int refusedCount;

  final bool isSyncing;

  /// When the queue was last fully drained, by the device clock.
  final DateTime? lastSyncedAt;

  /// Treats [Reachability.unknown] as online.
  ///
  /// At launch, before anything has been attempted, "offline" would be a guess — and the
  /// wrong guess in the alarming direction. The indicator says offline once an attempt has
  /// actually failed.
  bool get isOnline => reachability != Reachability.unreachable;

  bool get hasPendingWork => pendingCount > 0;

  /// Offline *and* holding unsent records — the state the attendant must act on.
  bool get needsAttention => !isOnline && hasPendingWork;

  /// Records needing a human decision before the trip can be closed cleanly.
  bool get hasRecordsNeedingReview =>
      flaggedForReviewCount > 0 || refusedCount > 0;

  SyncStatus copyWith({
    Reachability? reachability,
    int? pendingCount,
    int? flaggedForReviewCount,
    int? refusedCount,
    bool? isSyncing,
    DateTime? lastSyncedAt,
  }) {
    return SyncStatus(
      reachability: reachability ?? this.reachability,
      pendingCount: pendingCount ?? this.pendingCount,
      flaggedForReviewCount:
          flaggedForReviewCount ?? this.flaggedForReviewCount,
      refusedCount: refusedCount ?? this.refusedCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
        reachability,
        pendingCount,
        flaggedForReviewCount,
        refusedCount,
        isSyncing,
        lastSyncedAt,
      ];
}

/// How many records sit in each terminal or pending state.
class QueueCounts extends Equatable {
  const QueueCounts({
    this.pending = 0,
    this.inFlight = 0,
    this.flaggedForReview = 0,
    this.refused = 0,
  });

  final int pending;
  final int inFlight;
  final int flaggedForReview;
  final int refused;

  /// Anything not yet acknowledged, in flight or not — this is the number the attendant is
  /// shown, because from where they stand a record being uploaded right now is still a
  /// record that has not arrived.
  int get outstanding => pending + inFlight;

  @override
  List<Object?> get props => [pending, inFlight, flaggedForReview, refused];
}
