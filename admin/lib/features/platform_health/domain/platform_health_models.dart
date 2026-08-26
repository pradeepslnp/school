import 'package:equatable/equatable.dart';

/// A point-in-time read of `GET /platform/health` (screen A-62).
///
/// Deliberately not infrastructure telemetry (no heap, disk, or request-rate figures) — see
/// `GetPlatformHealthUseCase`'s Javadoc on the backend for why: nothing in this platform
/// collects those today, and a platform operator has no use for JVM internals when checking
/// whether things are basically working.
class PlatformHealth extends Equatable {
  const PlatformHealth({
    required this.databaseReachable,
    required this.totalOrganizations,
    required this.activeOrganizations,
    required this.suspendedOrganizations,
    required this.closedOrganizations,
    required this.checkedAt,
  });

  /// Best-effort, not a guarantee — see the backend Javadoc. A full outage usually surfaces
  /// as a failed request before this screen ever loads; this catches the narrower case where
  /// the platform-wide organization read itself fails while everything else responds.
  final bool databaseReachable;
  final int totalOrganizations;
  final int activeOrganizations;
  final int suspendedOrganizations;
  final int closedOrganizations;
  final DateTime checkedAt;

  @override
  List<Object?> get props => [
        databaseReachable,
        totalOrganizations,
        activeOrganizations,
        suspendedOrganizations,
        closedOrganizations,
        checkedAt,
      ];
}
