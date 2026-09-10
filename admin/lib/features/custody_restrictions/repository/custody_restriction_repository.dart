import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/custody_restriction_data_provider.dart';
import '../domain/custody_restriction_models.dart';

/// Turns custody-restriction transport into domain outcomes.
///
/// The bloc depends on this, never on [CustodyRestrictionDataProvider] directly.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class CustodyRestrictionRepository {
  CustodyRestrictionRepository({required this.dataProvider});

  final CustodyRestrictionDataProvider dataProvider;

  Future<Result<List<CustodyRestriction>>> list({required String studentId}) async {
    final response = await dataProvider.list(studentId: studentId);
    if (!response.isSuccess) return _toFailure<List<CustodyRestriction>>(response);

    final restrictions = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parse)
        .whereType<CustodyRestriction>()
        .toList(growable: false);
    return Success<List<CustodyRestriction>>(restrictions);
  }

  Future<Result<CustodyRestriction>> record({
    required String studentId,
    String? restrictedGuardianId,
    String? restrictedPersonName,
    required String restrictionType,
    required String reason,
    String? effectiveUntil,
  }) async {
    final response = await dataProvider.record(
      studentId: studentId,
      restrictedGuardianId: restrictedGuardianId,
      restrictedPersonName: restrictedPersonName,
      restrictionType: restrictionType,
      reason: reason.trim(),
      effectiveUntil: effectiveUntil,
    );
    if (!response.isSuccess) return _toFailure<CustodyRestriction>(response);

    final parsed = _parse(response.data);
    if (parsed == null) return const Failure<CustodyRestriction>(ErrorCode.internalError);
    return Success<CustodyRestriction>(parsed);
  }

  Future<Result<void>> lift({
    required String studentId,
    required String restrictionId,
  }) async {
    final response = await dataProvider.lift(
      studentId: studentId,
      restrictionId: restrictionId,
    );
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: response.errorBusinessRule,
    );
  }

  CustodyRestriction? _parse(Map<String, Object?> data) {
    final id = data['id'];
    final studentId = data['studentId'];
    final restrictionType = data['restrictionType'];
    final reason = data['reason'];
    final effectiveFrom = data['effectiveFrom'];
    final active = data['active'];
    if (id is! String ||
        studentId is! String ||
        restrictionType is! String ||
        reason is! String ||
        effectiveFrom is! String ||
        active is! bool) {
      return null;
    }
    final from = DateTime.tryParse(effectiveFrom);
    if (from == null) return null;

    return CustodyRestriction(
      id: id,
      studentId: studentId,
      restrictedGuardianId: data['restrictedGuardianId'] as String?,
      restrictedPersonName: data['restrictedPersonName'] as String?,
      restrictionType: restrictionType,
      reason: reason,
      effectiveFrom: from,
      effectiveUntil: data['effectiveUntil'] is String
          ? DateTime.tryParse(data['effectiveUntil']! as String)
          : null,
      active: active,
    );
  }
}
