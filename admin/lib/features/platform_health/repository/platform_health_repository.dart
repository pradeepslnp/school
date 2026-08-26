import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/platform_health_data_provider.dart';
import '../domain/platform_health_models.dart';

/// Turns Platform health transport into a domain outcome (A-62).
///
/// The bloc depends on this, never on [PlatformHealthDataProvider] — matching every other
/// repository in this console, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class PlatformHealthRepository {
  PlatformHealthRepository({required this.dataProvider});

  final PlatformHealthDataProvider dataProvider;

  Future<Result<PlatformHealth>> getHealth() async {
    final response = await dataProvider.getHealth();
    if (!response.isSuccess) return _toFailure<PlatformHealth>(response);

    final health = _parseHealth(response.data);
    if (health == null) {
      return const Failure<PlatformHealth>(ErrorCode.internalError);
    }
    return Success<PlatformHealth>(health);
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }

    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: response.errorBusinessRule,
    );
  }

  PlatformHealth? _parseHealth(Map<String, Object?> data) {
    final databaseReachable = data['databaseReachable'];
    final total = data['totalOrganizations'];
    final active = data['activeOrganizations'];
    final suspended = data['suspendedOrganizations'];
    final closed = data['closedOrganizations'];
    final checkedAt = data['checkedAt'];
    if (databaseReachable is! bool ||
        total is! int ||
        active is! int ||
        suspended is! int ||
        closed is! int ||
        checkedAt is! String) {
      return null;
    }

    final parsedCheckedAt = DateTime.tryParse(checkedAt);
    if (parsedCheckedAt == null) return null;

    return PlatformHealth(
      databaseReachable: databaseReachable,
      totalOrganizations: total,
      activeOrganizations: active,
      suspendedOrganizations: suspended,
      closedOrganizations: closed,
      checkedAt: parsedCheckedAt,
    );
  }
}
