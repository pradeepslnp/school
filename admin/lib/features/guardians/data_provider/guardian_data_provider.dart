import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for a student's guardians (GRD-001, GRD-002, screen A-11).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console. This layer speaks endpoints and JSON only; deciding what a failure means
/// is [GuardianRepository]'s job.
///
/// Contract: `STUDENTS_GUARDIANS_API.md` §Guardian–Student Links.
class GuardianDataProvider {
  GuardianDataProvider({required this.client});

  final RestClient client;

  /// `GET /students/{studentId}/guardians` (`PERM-STUDENT-VIEW`).
  Future<ApiResponse> listGuardians({required String studentId}) {
    return client.get('/students/$studentId/guardians');
  }

  /// `POST /students/{studentId}/guardians` (`PERM-GUARDIAN-LINK`) — creates the parent's login
  /// from their phone (reusing one if the phone is already known here) and links them to the
  /// child with the rights given.
  Future<ApiResponse> addGuardian({
    required String studentId,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String relationshipType,
    required bool canView,
    required bool canReceiveNotifications,
    required bool canAuthoriseHandover,
    required bool canDeclareAbsence,
    required bool isPrimary,
  }) {
    return client.post(
      '/students/$studentId/guardians',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'relationshipType': relationshipType,
        'canView': canView,
        'canReceiveNotifications': canReceiveNotifications,
        'canAuthoriseHandover': canAuthoriseHandover,
        'canDeclareAbsence': canDeclareAbsence,
        'isPrimary': isPrimary,
      },
    );
  }
}
