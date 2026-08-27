import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for the audit trail (AUD-002, AUD-003, screens A-54/A-55).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider in
/// this console. Read-only: there is no create/update/delete, because audit records cannot be
/// written or altered through any API (BR-AUD-002).
///
/// Contract: `REPORTING_AUDIT_CONFIG_API.md` §Audit.
class AuditDataProvider {
  AuditDataProvider({required this.client});

  final RestClient client;

  /// `GET /audit-records` (`PERM-AUDIT-VIEW`) — the trail, most recent first, tenant-scoped.
  Future<ApiResponse> listRecords({String? action, String? subjectType, int limit = 100}) {
    return client.get('/audit-records', query: {
      if (action != null && action.isNotEmpty) 'action': action,
      if (subjectType != null && subjectType.isNotEmpty) 'subjectType': subjectType,
      'limit': limit,
    });
  }

  /// `GET /audit-records/overrides` (`PERM-AUDIT-VIEW`) — the override register: only actions that
  /// carry a reason (AUD-003).
  Future<ApiResponse> listOverrides({int limit = 100}) {
    return client.get('/audit-records/overrides', query: {'limit': limit});
  }
}
