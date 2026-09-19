import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for a student's assigned bus and crew (STU-009, screen A-11).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider in
/// this console. Deciding what a failure means is `StudentTransportRepository`'s job.
///
/// Contract: `STUDENTS_GUARDIANS_API.md` §Student transport and journey.
class StudentTransportDataProvider {
  StudentTransportDataProvider({required this.client});

  final RestClient client;

  /// `GET /students/{studentId}/transport` (`PERM-STUDENT-VIEW`, school-scoped). Recorded
  /// server-side as an access to the child's data (BR-IAM-012), so it is fetched when the record
  /// is opened, not speculatively.
  Future<ApiResponse> getTransport({required String studentId}) {
    return client.get('/students/$studentId/transport');
  }
}
