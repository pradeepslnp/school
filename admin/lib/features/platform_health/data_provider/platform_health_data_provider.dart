import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for the Platform health screen (A-62).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data
/// provider in this console (PROJECT_STRUCTURE.md).
class PlatformHealthDataProvider {
  PlatformHealthDataProvider({required this.client});

  final RestClient client;

  /// `GET /platform/health` — `SUPER_ADMIN` only (`PERM-PLATFORM-HEALTH-VIEW`).
  Future<ApiResponse> getHealth() {
    return client.get('/platform/health');
  }
}
