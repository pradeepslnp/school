import 'package:equatable/equatable.dart';

/// Where one child on a trip stands right now.
///
/// `unknown` is not an oversight: statuses ship additively within `v1`, and a handset in the field
/// will meet one it was not built with. Showing it as unknown is safe; mapping it onto the nearest
/// familiar value would let a crew read "not yet boarded" for something else entirely.
enum ManifestEntryStatus {
  expected,
  boarded,
  alighted,
  noShow,
  absent,
  unknown;

  static ManifestEntryStatus fromWire(String? wire) => switch (wire) {
        'EXPECTED' => expected,
        'BOARDED' => boarded,
        'ALIGHTED' => alighted,
        'NO_SHOW' => noShow,
        'ABSENT' => absent,
        _ => unknown,
      };

  /// Whether the crew can record a board for this child now.
  bool get canBoard => this == expected || this == alighted;

  /// Whether the crew can record an alight — only for someone actually aboard.
  bool get canAlight => this == boarded;
}

/// One child the trip expects, as `GET /trips/{id}/manifest` returns them.
///
/// [pendingSync] is local only: the event is written to the outbound queue and shown immediately,
/// long before the server has heard of it (ADR-0008). A crew at a kerb must see the tap land at
/// once, and the row must not pretend the server has confirmed anything.
class ManifestChild extends Equatable {
  const ManifestChild({
    required this.studentId,
    required this.studentName,
    required this.stopSequenceNo,
    required this.status,
    this.className,
    this.expectedStopId,
    this.expectedStopName,
    this.scheduledStopTime,
    this.lastEventAt,
    this.pendingSync = false,
  });

  final String studentId;
  final String studentName;
  final String? className;
  final String? expectedStopId;
  final String? expectedStopName;
  final int stopSequenceNo;
  final String? scheduledStopTime;
  final ManifestEntryStatus status;
  final DateTime? lastEventAt;
  final bool pendingSync;

  ManifestChild copyWith({ManifestEntryStatus? status, bool? pendingSync}) {
    return ManifestChild(
      studentId: studentId,
      studentName: studentName,
      className: className,
      expectedStopId: expectedStopId,
      expectedStopName: expectedStopName,
      stopSequenceNo: stopSequenceNo,
      scheduledStopTime: scheduledStopTime,
      status: status ?? this.status,
      lastEventAt: lastEventAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  List<Object?> get props => [studentId, status, pendingSync];
}
