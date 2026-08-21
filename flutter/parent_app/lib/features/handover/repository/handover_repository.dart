import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/handover_data_provider.dart';
import 'models/handover_code.dart';

/// Turns handover-code transport into domain meaning.
///
/// The BLoC depends on this, never on [HandoverDataProvider] (ENGINEERING_PRINCIPLES.md §4).
class HandoverRepository {
  HandoverRepository({required this.dataProvider});

  final HandoverDataProvider dataProvider;

  Future<Result<HandoverCode>> requestCode({required String studentId}) async {
    final response = await dataProvider.requestCode(studentId: studentId);
    if (!response.isSuccess) return _toFailure<HandoverCode>(response);

    final code = _parse(response.data, studentId);
    if (code == null) return const Failure<HandoverCode>(ErrorCode.internalError);
    return Success<HandoverCode>(code);
  }

  static HandoverCode? _parse(Map<String, Object?> raw, String studentId) {
    final code = raw['code'] as String?;
    final expiresAt = DateTime.tryParse(raw['expiresAt'] as String? ?? '');
    if (code == null || expiresAt == null) return null;

    return HandoverCode(
      studentId: (raw['studentId'] as String?) ?? studentId,
      code: code,
      // Server sends UTC (docs/04-api/API_STANDARDS.md); local for a countdown a parent
      // reads against their own clock.
      expiresAt: expiresAt.toLocal(),
    );
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return const Failure(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
    );
  }
}
