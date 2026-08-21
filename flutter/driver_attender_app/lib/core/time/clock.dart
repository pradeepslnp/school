/// The current time, as a dependency.
///
/// Injected rather than called statically so a test can advance time instead of waiting for
/// it, and so the one place that reads the handset clock is visible in a constructor
/// signature. In this app that visibility is the point: **the device clock is not
/// authoritative** (ADR-0008, BR-BOARD-008), and every read of it eventually needs a skew
/// estimate attached.
abstract interface class Clock {
  /// Now, in UTC. Always UTC — a local `DateTime` that crosses a storage or wire boundary
  /// loses its offset silently and comes back wrong.
  DateTime nowUtc();
}

/// The handset clock.
///
/// The user can change it, and it drifts. Everything written through this clock is stamped
/// with a measured skew so a later investigation can tell what the device believed from what
/// the server observed (core/time/clock_skew.dart).
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
