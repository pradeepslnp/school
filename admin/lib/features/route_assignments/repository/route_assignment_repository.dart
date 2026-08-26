import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/route_assignment_data_provider.dart';
import '../domain/route_assignment_models.dart';

/// Turns route-assignment transport into domain outcomes.
///
/// The bloc depends on this, never on [RouteAssignmentDataProvider] directly — matching
/// `RouteRepository`, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class RouteAssignmentRepository {
  RouteAssignmentRepository({required this.dataProvider});

  final RouteAssignmentDataProvider dataProvider;

  Future<Result<List<RouteAssignment>>> listForStudent({required String studentId}) async {
    final response = await dataProvider.listForStudent(studentId: studentId);
    if (!response.isSuccess) return _toFailure<List<RouteAssignment>>(response);

    final assignments = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parse)
        .whereType<RouteAssignment>()
        .toList(growable: false);
    return Success<List<RouteAssignment>>(assignments);
  }

  Future<Result<RouteAssignment>> assign({
    required String routeId,
    required String studentId,
    required String stopId,
    required String direction,
  }) async {
    final response = await dataProvider.assign(
      routeId: routeId,
      studentId: studentId,
      stopId: stopId,
      direction: direction,
    );
    if (!response.isSuccess) return _toFailure<RouteAssignment>(response);

    final assignment = _parse(response.data);
    if (assignment == null) {
      return const Failure<RouteAssignment>(ErrorCode.internalError);
    }
    return Success<RouteAssignment>(assignment);
  }

  Future<Result<void>> remove({required String assignmentId}) async {
    final response = await dataProvider.remove(assignmentId: assignmentId);
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
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

  RouteAssignment? _parse(Map<String, Object?> data) {
    final id = data['id'];
    final routeId = data['routeId'];
    final routeCode = data['routeCode'];
    final routeName = data['routeName'];
    final stopId = data['stopId'];
    final stopName = data['stopName'];
    final studentId = data['studentId'];
    final direction = data['direction'];
    if (id is! String ||
        routeId is! String ||
        routeCode is! String ||
        routeName is! String ||
        stopId is! String ||
        stopName is! String ||
        studentId is! String ||
        direction is! String) {
      return null;
    }
    return RouteAssignment(
      id: id,
      routeId: routeId,
      routeCode: routeCode,
      routeName: routeName,
      stopId: stopId,
      stopName: stopName,
      studentId: studentId,
      direction: direction,
      validFrom: _parseDate(data['validFrom'] as String?),
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
