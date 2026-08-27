import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/audit_data_provider.dart';
import '../domain/audit_models.dart';

/// Turns audit transport into domain outcomes.
///
/// The bloc depends on this, never on [AuditDataProvider] directly — matching `UserRepository`, so
/// a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class AuditRepository {
  AuditRepository({required this.dataProvider});

  final AuditDataProvider dataProvider;

  Future<Result<List<AuditRecord>>> listRecords({
    String? action,
    String? subjectType,
    int limit = 100,
  }) async {
    final response = await dataProvider.listRecords(
      action: action,
      subjectType: subjectType,
      limit: limit,
    );
    return _toList(response);
  }

  Future<Result<List<AuditRecord>>> listOverrides({int limit = 100}) async {
    final response = await dataProvider.listOverrides(limit: limit);
    return _toList(response);
  }

  Result<List<AuditRecord>> _toList(ApiResponse response) {
    if (!response.isSuccess) {
      if (response.isTransportFailure) {
        return const Failure<List<AuditRecord>>(ErrorCode.dependencyUnavailable);
      }
      return Failure<List<AuditRecord>>(
        ErrorCode.fromWire(response.errorCode),
        messageKey: response.errorMessageKey,
        businessRule: response.errorBusinessRule,
      );
    }

    final records = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parse)
        .whereType<AuditRecord>()
        .toList(growable: false);
    return Success<List<AuditRecord>>(records);
  }

  AuditRecord? _parse(Map<String, Object?> data) {
    final id = data['id'];
    final actorType = data['actorType'];
    final action = data['action'];
    final subjectType = data['subjectType'];
    final source = data['source'];
    final occurredAt = data['occurredAt'];
    if (id is! String ||
        actorType is! String ||
        action is! String ||
        subjectType is! String ||
        source is! String ||
        occurredAt is! String) {
      return null;
    }
    final when = DateTime.tryParse(occurredAt);
    if (when == null) return null;
    return AuditRecord(
      id: id,
      actorId: data['actorId'] as String?,
      actorType: actorType,
      actorRole: data['actorRole'] as String?,
      action: action,
      subjectType: subjectType,
      subjectId: data['subjectId'] as String?,
      reason: data['reason'] as String?,
      source: source,
      occurredAt: when,
    );
  }
}
