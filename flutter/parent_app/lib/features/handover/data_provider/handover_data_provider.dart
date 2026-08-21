import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for P-12, requesting a handover verification code.
///
/// Contract: `POST /students/{id}/handover-code` (guardian-docs/05-ui/PARENT_APP.md § P-12),
/// served by MOD-09's minimal boarding slice.
class HandoverDataProvider {
  HandoverDataProvider({required this.client});

  final RestClient client;

  /// Requests a fresh code, superseding any code already live for this student.
  ///
  /// No idempotency key: reopening this screen before an earlier code expired should hand
  /// back a code with its full lifetime, not the remainder of one already shown to someone,
  /// so this is deliberately not retried as an idempotent call.
  Future<ApiResponse> requestCode({required String studentId}) =>
      client.post('/students/$studentId/handover-code');
}
