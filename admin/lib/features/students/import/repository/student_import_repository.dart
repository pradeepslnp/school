import '../../../../core/domain.dart';
import '../../../../core/network/api_response.dart';
import '../data_provider/student_import_data_provider.dart';
import '../domain/student_import_models.dart';

/// Turns a bulk-import upload into a domain outcome.
///
/// The bloc depends on this, never on [StudentImportDataProvider] directly — matching every
/// other feature here.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class StudentImportRepository {
  StudentImportRepository({required this.dataProvider});

  final StudentImportDataProvider dataProvider;

  Future<Result<StudentImportResult>> importCsv({
    required String schoolId,
    required PickedCsv file,
  }) async {
    final response = await dataProvider.importFile(
      schoolId: schoolId,
      fileName: file.name,
      bytes: file.bytes,
    );
    return _toResult(response);
  }

  Future<Result<StudentImportResult>> getResult({required String jobId}) async {
    final response = await dataProvider.getImport(jobId: jobId);
    return _toResult(response);
  }

  Result<StudentImportResult> _toResult(ApiResponse response) {
    if (!response.isSuccess) {
      if (response.isTransportFailure) {
        return Failure<StudentImportResult>(ErrorCode.dependencyUnavailable);
      }
      return Failure<StudentImportResult>(
        ErrorCode.fromWire(response.errorCode),
        messageKey: response.errorMessageKey,
        businessRule: response.errorBusinessRule,
      );
    }

    final parsed = _parse(response.data);
    if (parsed == null) {
      return const Failure<StudentImportResult>(ErrorCode.internalError);
    }
    return Success<StudentImportResult>(parsed);
  }

  StudentImportResult? _parse(Map<String, Object?> data) {
    final jobId = data['jobId'];
    final status = data['status'];
    final totalRows = data['totalRows'];
    final successCount = data['successCount'];
    final errorCount = data['errorCount'];
    if (jobId is! String ||
        status is! String ||
        totalRows is! int ||
        successCount is! int ||
        errorCount is! int) {
      return null;
    }

    final errors = (data['errors'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(_parseRowError)
        .whereType<StudentImportRowError>()
        .toList(growable: false);

    return StudentImportResult(
      jobId: jobId,
      status: status,
      totalRows: totalRows,
      successCount: successCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  StudentImportRowError? _parseRowError(Map<String, Object?> data) {
    final row = data['row'];
    final code = data['code'];
    final message = data['message'];
    if (row is! int || code is! String || message is! String) return null;
    return StudentImportRowError(
      row: row,
      field: data['field'] as String?,
      code: code,
      message: message,
    );
  }
}
