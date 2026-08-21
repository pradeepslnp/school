import 'dart:io';

import 'clock.dart';

/// How far the device clock is from the server's, and when that was last established.
///
/// ADR-0008 requires two timestamps on every safety record: `occurredAt` from the device,
/// and `recordedAt` set by the server. Neither alone is enough after an incident — the
/// device time is what the attendant saw, the server time is what can be trusted, and the
/// difference between them is what makes the first interpretable. This type is that
/// difference, carried explicitly rather than assumed to be zero.
class ClockSkew {
  const ClockSkew({
    required this.seconds,
    required this.measuredAt,
    required this.uncertaintySeconds,
  });

  /// `deviceClock - serverClock`, in seconds. Positive means the device is ahead.
  final int seconds;

  /// Device time at which this measurement was taken.
  ///
  /// Stored so a record can say how stale its skew estimate was. A skew measured eight hours
  /// before a boarding event is weaker evidence than one measured a minute before, and an
  /// investigation should be able to see which it is holding.
  final DateTime measuredAt;

  /// Half the request round trip, in seconds — the residual error in [seconds].
  ///
  /// The `Date` header is stamped somewhere between the request leaving and the response
  /// arriving, and it has one-second resolution. On a weak mobile link that is easily a
  /// couple of seconds, which matters when the question is whether a child boarded before
  /// or after the bus left. Recorded rather than rounded away.
  final int uncertaintySeconds;

  // A null [ClockSkew] means no measurement has ever been taken, and that is deliberately
  // not the same as a measured skew of zero: "skew unknown" is honest, while "skew 0" on a
  // device that has never reached the server is a claim the app cannot support.

  Map<String, Object?> toJson() => {
        'seconds': seconds,
        'measuredAt': measuredAt.toIso8601String(),
        'uncertaintySeconds': uncertaintySeconds,
      };

  static ClockSkew? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final seconds = json['seconds'];
    final measuredAt = json['measuredAt'];
    if (seconds is! int || measuredAt is! String) return null;
    final parsed = DateTime.tryParse(measuredAt);
    if (parsed == null) return null;
    return ClockSkew(
      seconds: seconds,
      measuredAt: parsed.toUtc(),
      uncertaintySeconds: json['uncertaintySeconds'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'ClockSkew(${seconds}s ±${uncertaintySeconds}s at $measuredAt)';
}

/// Derives a [ClockSkew] from the `Date` header of a real API response.
///
/// Deliberately not NTP or a dedicated time endpoint. Every sync already talks to the
/// server, and the header is on every reply — so the estimate refreshes at exactly the
/// moments it is needed, with no extra request from a vehicle on a metered, intermittent
/// link.
class ClockSkewEstimator {
  ClockSkewEstimator({required Clock clock}) : _clock = clock;

  final Clock _clock;

  /// Measures skew from one completed exchange.
  ///
  /// [sentAt] and [receivedAt] are device-clock readings taken either side of the request;
  /// their midpoint is the best guess at the device time corresponding to the server's
  /// `Date`. Returns null when the header is absent or unparseable — an unmeasurable
  /// exchange leaves the previous estimate alone rather than replacing it with a fabricated
  /// one.
  ClockSkew? measure({
    required Map<String, String> responseHeaders,
    required DateTime sentAt,
    required DateTime receivedAt,
    String? envelopeTimestamp,
  }) {
    // The `Date` header first, because it is present on every reply including errors. The
    // envelope's `meta.timestamp` (API_STANDARDS.md) is the fallback for the case where a
    // proxy strips or rewrites the header — it comes from the application rather than the
    // edge, so it is the more trustworthy of the two when both disagree, but it is absent
    // from non-JSON replies.
    final serverTime =
        _parseDate(responseHeaders) ?? _parseIso(envelopeTimestamp);
    if (serverTime == null) return null;

    final roundTrip = receivedAt.difference(sentAt);

    // An implausible round trip means the device clock moved during the request — a user
    // changing the time, or a suspend/resume. The measurement is unusable; the previous one
    // stands.
    if (roundTrip.isNegative || roundTrip > const Duration(minutes: 2)) {
      return null;
    }

    final deviceAtServerStamp = sentAt.add(roundTrip ~/ 2);

    return ClockSkew(
      seconds: deviceAtServerStamp.difference(serverTime).inSeconds,
      measuredAt: _clock.nowUtc(),
      uncertaintySeconds: (roundTrip.inMilliseconds / 2000).ceil(),
    );
  }

  static DateTime? _parseDate(Map<String, String> headers) {
    // Header names are case-insensitive (RFC 9110); http lowercases them, but a proxy in
    // front of a test server may not, so both are accepted.
    final raw = headers['date'] ?? headers['Date'];
    if (raw == null || raw.isEmpty) return null;
    try {
      return HttpDate.parse(raw).toUtc();
    } on FormatException {
      return null;
    }
  }

  static DateTime? _parseIso(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}
