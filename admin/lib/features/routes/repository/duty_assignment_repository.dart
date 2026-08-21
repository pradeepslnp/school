import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/duty_assignment_data_provider.dart';
import '../domain/duty_assignment_models.dart';

/// Turns duty-assignment transport into domain outcomes.
///
/// The bloc depends on this, never on [DutyAssignmentDataProvider] directly — matching
/// `RouteRepository`, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class DutyAssignmentRepository {
  DutyAssignmentRepository({required this.dataProvider});

  final DutyAssignmentDataProvider dataProvider;

  Future<Result<CreatedDutyAssignment>> assignDuty({
    required String routeId,
    required String staffId,
    required String role,
    String? direction,
  }) async {
    final response = await dataProvider.assignDuty(
      routeId: routeId,
      staffId: staffId.trim(),
      role: role,
      direction: direction,
    );
    if (!response.isSuccess) return _toFailure<CreatedDutyAssignment>(response);

    final assignment = _parse(response.data);
    if (assignment == null) {
      return const Failure<CreatedDutyAssignment>(ErrorCode.internalError);
    }
    return Success<CreatedDutyAssignment>(assignment);
  }

  Future<Result<List<CreatedDutyAssignment>>> listDutyAssignments({required String routeId}) async {
    final response = await dataProvider.listDutyAssignments(routeId: routeId);
    if (!response.isSuccess) return _toFailure<List<CreatedDutyAssignment>>(response);

    final assignments = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parse)
        .whereType<CreatedDutyAssignment>()
        .toList(growable: false);
    return Success<List<CreatedDutyAssignment>>(assignments);
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

  CreatedDutyAssignment? _parse(Map<String, Object?> data) {
    final id = data['id'];
    final staffId = data['staffId'];
    final routeId = data['routeId'];
    final role = data['role'];
    final active = data['active'];
    if (id is! String || staffId is! String || routeId is! String || role is! String || active is! bool) {
      return null;
    }
    return CreatedDutyAssignment(
      id: id,
      staffId: staffId,
      routeId: routeId,
      role: role,
      direction: data['direction'] as String?,
      active: active,
    );
  }
}
