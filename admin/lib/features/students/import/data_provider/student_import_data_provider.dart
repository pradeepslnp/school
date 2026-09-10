import '../../../../core/network/api_response.dart';
import '../../../../core/network/rest_client.dart';

/// Transport for bulk student import (STU-002, screen A-12).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console. This layer speaks endpoints only; deciding what a failure means is
/// [StudentImportRepository]'s job.
///
/// Contract: `STUDENTS_GUARDIANS_API.md` §POST /students/import.
class StudentImportDataProvider {
  StudentImportDataProvider({required this.client});

  final RestClient client;

  /// `POST /students/import` — `multipart/form-data` with the school and the file
  /// (`PERM-STUDENT-IMPORT`). Not retried: a repeated upload would enrol every child twice.
  Future<ApiResponse> importFile({
    required String schoolId,
    required String fileName,
    required List<int> bytes,
  }) {
    return client.postMultipart(
      '/students/import',
      fileBytes: bytes,
      fileName: fileName,
      fields: {'schoolId': schoolId},
    );
  }

  /// `GET /students/import/{jobId}` — the result of an earlier upload, for reopening a job.
  Future<ApiResponse> getImport({required String jobId}) {
    return client.get('/students/import/$jobId');
  }
}
