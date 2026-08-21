import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for P-07, authorised pickup persons.
///
/// Contract: `GET`/`POST /students/{studentId}/pickup-persons`,
/// `DELETE /students/{studentId}/pickup-persons/{id}`
/// (docs/04-api/STUDENTS_GUARDIANS_API.md), served by MOD-04.
class PickupPersonsDataProvider {
  PickupPersonsDataProvider({required this.client});

  final RestClient client;

  Future<ApiResponse> fetchPickupPersons({required String studentId}) =>
      client.get('/students/$studentId/pickup-persons');

  /// Nominates someone to collect this child.
  ///
  /// Refused with `403 GUARDIAN_NOT_AUTHORISED_TO_NOMINATE` unless the calling guardian holds
  /// the handover right on *this* relationship (BR-GRD-006) — a right they may hold for one
  /// child and not another, which is why the app cannot decide it locally.
  ///
  /// `validUntil` is mandatory server-side: nominations always expire (BR-GRD-005).
  Future<ApiResponse> addPickupPerson({
    required String studentId,
    required String fullName,
    required String phone,
    required String? relationshipNote,
    required DateTime validFrom,
    required DateTime validUntil,
  }) {
    return client.post(
      '/students/$studentId/pickup-persons',
      body: {
        'fullName': fullName,
        'phone': phone,
        'relationshipNote': relationshipNote,
        'validFrom': validFrom.toUtc().toIso8601String(),
        'validUntil': validUntil.toUtc().toIso8601String(),
      },
    );
  }

  /// Revocation takes effect immediately (BR-GRD-007).
  Future<ApiResponse> revokePickupPerson({
    required String studentId,
    required String pickupPersonId,
  }) =>
      client.delete('/students/$studentId/pickup-persons/$pickupPersonId');
}
