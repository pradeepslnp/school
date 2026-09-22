import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for duty assignment (STF-004).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console (PROJECT_STRUCTURE.md). This layer speaks endpoints and JSON only; deciding
/// what a failure means is [DutyAssignmentRepository]'s job.
///
/// Contract: [`FLEET_STAFF_ROUTES_API.md`] §Duty Assignments.
class DutyAssignmentDataProvider {
  DutyAssignmentDataProvider({required this.client});

  final RestClient client;

  /// `POST /routes/{routeId}/duty-assignments` — assigns a driver or attendant to a route's
  /// standing roster (`PERM-DUTY-ASSIGN`).
  Future<ApiResponse> assignDuty({
    required String routeId,
    required String staffId,
    required String role,
    String? direction,
  }) {
    return client.post(
      '/routes/$routeId/duty-assignments',
      body: {
        'staffId': staffId,
        'role': role,
        if (direction != null && direction.isNotEmpty) 'direction': direction,
      },
    );
  }

  /// `GET /routes/{routeId}/duty-assignments` — the route's standing crew (`PERM-ROUTE-VIEW`).
  Future<ApiResponse> listDutyAssignments({required String routeId}) {
    return client.get('/routes/$routeId/duty-assignments');
  }

  /// `POST /duty-assignments/{id}/replace` (`PERM-DUTY-ASSIGN`) — puts a different person on this
  /// duty, in one audited step. The replacement inherits the role and direction.
  ///
  /// A `POST`, so [RestClient] never retries it: a retried replacement would take the new crew
  /// member off again and put a third one on.
  Future<ApiResponse> replaceDuty({
    required String assignmentId,
    required String staffId,
    required String reason,
  }) {
    return client.post(
      '/duty-assignments/$assignmentId/replace',
      body: {'staffId': staffId, 'reason': reason},
    );
  }

  /// `DELETE /duty-assignments/{id}` (`PERM-DUTY-ASSIGN`) — takes the crew member off this route's
  /// standing roster, leaving the slot empty.
  Future<ApiResponse> removeDuty({required String assignmentId}) {
    return client.delete('/duty-assignments/$assignmentId');
  }
}
