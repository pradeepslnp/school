import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for student route assignment (RTE-003).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider in
/// this console. This layer speaks endpoints and JSON only; deciding what a failure means is
/// [RouteAssignmentRepository]'s job.
///
/// Contract: `FLEET_STAFF_ROUTES_API.md` §Student Route Assignments.
class RouteAssignmentDataProvider {
  RouteAssignmentDataProvider({required this.client});

  final RestClient client;

  /// `POST /routes/{routeId}/students` (`PERM-ROUTE-ASSIGN-STUDENT`) — assigns a student to a stop
  /// on this route for one direction.
  Future<ApiResponse> assign({
    required String routeId,
    required String studentId,
    required String stopId,
    required String direction,
  }) {
    return client.post(
      '/routes/$routeId/students',
      body: {
        'studentId': studentId,
        'stopId': stopId,
        'direction': direction,
      },
    );
  }

  /// `GET /students/{studentId}/route-assignments` (`PERM-STUDENT-VIEW`).
  Future<ApiResponse> listForStudent({required String studentId}) {
    return client.get('/students/$studentId/route-assignments');
  }

  /// `DELETE /route-assignments/{id}` (`PERM-ROUTE-ASSIGN-STUDENT`) — deactivates an assignment.
  Future<ApiResponse> remove({required String assignmentId}) {
    return client.delete('/route-assignments/$assignmentId');
  }
}
