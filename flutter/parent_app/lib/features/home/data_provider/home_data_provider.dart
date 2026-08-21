import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for the dashboard.
///
/// Calls [RestClient] rather than `package:http` directly, so timeouts, headers, retry
/// policy, and response decoding stay decided in one place
/// (docs/06-development/PROJECT_STRUCTURE.md).
///
/// This layer speaks endpoints and JSON. Deciding what a failure *means* is the
/// repository's job, and keeping that split is what lets the repository be tested without
/// a socket.
///
/// Contract: docs/04-api/STUDENTS_GUARDIANS_API.md — `GET /guardians/me/students`, served by
/// MOD-18 (ADR-0010). Live since the parent read model landed; the fixture this file used to
/// return was shaped to the same contract, so nothing above this layer changed when it went.
class HomeDataProvider {
  HomeDataProvider({required this.client});

  final RestClient client;

  /// `GET /guardians/me/students` — the calling guardian's own children, and where each one
  /// is right now.
  ///
  /// Scoped server-side to the caller's children (BR-IAM-005). The app sends no guardian or
  /// student identifier: an endpoint that accepted one would be an endpoint that could be
  /// asked about somebody else's child.
  Future<ApiResponse> fetchChildren() => client.get('/guardians/me/students');
}
