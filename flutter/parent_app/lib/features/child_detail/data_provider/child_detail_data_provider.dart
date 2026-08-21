import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for P-03, one child's detail.
///
/// Contract: `GET /guardians/me/students/{studentId}` — the dashboard read narrowed to one
/// child and extended with the day's legs, served by MOD-18 (ADR-0010).
///
/// Scoped the same way as the list endpoint: the guardian's own children only (BR-IAM-005).
/// A student the caller holds no active link to is refused with `403 AUTH_SCOPE_DENIED`
/// rather than `404` — within a tenant that is the honest answer, and `404` would let a
/// caller probe for which children exist (docs/04-api/API_STANDARDS.md § 403 vs 404).
class ChildDetailDataProvider {
  ChildDetailDataProvider({required this.client});

  final RestClient client;

  Future<ApiResponse> fetchDetail({required String studentId}) =>
      client.get('/guardians/me/students/$studentId');
}
