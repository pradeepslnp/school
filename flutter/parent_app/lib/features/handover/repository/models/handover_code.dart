import 'package:flutter/foundation.dart';

/// A short-lived verification code shown to the bus attendant at drop — P-12.
///
/// This is what the parent shows; it is not itself a handover. Verifying and redeeming it at
/// the vehicle is the attendant-side flow (BR-HAND-001 through BR-HAND-007), which this app
/// does not implement.
@immutable
class HandoverCode {
  const HandoverCode({
    required this.studentId,
    required this.code,
    required this.expiresAt,
  });

  final String studentId;

  /// Exactly six digits. Also the QR payload — a second, independent secret would be one
  /// more thing that can fail to match at the vehicle.
  final String code;

  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration remaining([DateTime? now]) {
    final diff = expiresAt.difference(now ?? DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// The mockup's grouped display: "4 8 2 9 1 3".
  String get grouped => code.split('').join(' ');
}
