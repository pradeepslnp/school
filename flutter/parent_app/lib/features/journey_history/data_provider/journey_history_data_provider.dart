import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for P-05, journey history.
///
/// Contract: `GET /guardians/me/students/{studentId}/journey-history`, served by MOD-18
/// (ADR-0010). A guardian-facing digest over the boarding record (BRD-003), collapsed to one
/// row per leg per day — a parent does not want raw position samples, they want "did Aarav
/// get to school on Tuesday, and when".
///
/// Scoped to the caller's own children (BR-IAM-005); a student they hold no active link to
/// returns an empty list rather than a refusal, so nothing is learned from the difference.
class JourneyHistoryDataProvider {
  JourneyHistoryDataProvider({required this.client});

  final RestClient client;

  Future<ApiResponse> fetchHistory({required String studentId}) =>
      client.get('/guardians/me/students/$studentId/journey-history');
}
