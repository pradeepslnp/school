import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for custody restrictions (GRD-006, screen A-14).
///
/// Calls [RestClient] rather than `package:http` directly. This layer speaks endpoints and JSON
/// only; deciding what a failure means is [CustodyRestrictionRepository]'s job.
///
/// Contract: `STUDENTS_GUARDIANS_API.md` § Custody Restrictions. Every call requires
/// `PERM-CUSTODY-RESTRICTION-MANAGE` — read included, unlike the rest of the student record.
class CustodyRestrictionDataProvider {
  CustodyRestrictionDataProvider({required this.client});

  final RestClient client;

  Future<ApiResponse> list({required String studentId}) {
    return client.get('/students/$studentId/custody-restrictions');
  }

  Future<ApiResponse> record({
    required String studentId,
    String? restrictedGuardianId,
    String? restrictedPersonName,
    required String restrictionType,
    required String reason,
    String? effectiveFrom,
    String? effectiveUntil,
  }) {
    return client.post(
      '/students/$studentId/custody-restrictions',
      body: {
        if (restrictedGuardianId != null && restrictedGuardianId.isNotEmpty)
          'restrictedGuardianId': restrictedGuardianId,
        if (restrictedPersonName != null && restrictedPersonName.isNotEmpty)
          'restrictedPersonName': restrictedPersonName,
        'restrictionType': restrictionType,
        'reason': reason,
        if (effectiveFrom != null && effectiveFrom.isNotEmpty) 'effectiveFrom': effectiveFrom,
        if (effectiveUntil != null && effectiveUntil.isNotEmpty) 'effectiveUntil': effectiveUntil,
      },
    );
  }

  Future<ApiResponse> lift({required String studentId, required String restrictionId}) {
    return client.delete('/students/$studentId/custody-restrictions/$restrictionId');
  }
}
