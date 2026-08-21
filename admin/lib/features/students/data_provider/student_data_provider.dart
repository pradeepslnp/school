import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for the student register (A-10) and student detail (A-11).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider
/// in this console. This layer speaks endpoints and JSON only; deciding what a failure means
/// is [StudentRepository]'s job.
///
/// Contract: `STUDENTS_GUARDIANS_API.md` §Students.
class StudentDataProvider {
  StudentDataProvider({required this.client});

  final RestClient client;

  /// `GET /students?schoolId=&cursor=&limit=` — one page of a school's register (STU-001,
  /// `PERM-STUDENT-VIEW`).
  ///
  /// Cursor-paged rather than offset-paged: a school has thousands of students, and an offset
  /// shifts under concurrent enrolment so a child can be skipped between pages. [cursor] is
  /// whatever the previous response's `meta.pagination.nextCursor` held.
  Future<ApiResponse> listStudents({
    required String schoolId,
    String? cursor,
    int? limit,
  }) {
    return client.get('/students', query: {
      'schoolId': schoolId,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      if (limit != null) 'limit': '$limit',
    });
  }

  /// `GET /students/{id}` — one student (STU-001, `PERM-STUDENT-VIEW`).
  ///
  /// Every call by a non-guardian writes a data-access record server-side (BR-IAM-012), so
  /// this is not a free read to make speculatively — fetch it when the operator opens a
  /// record, not to warm a cache.
  Future<ApiResponse> getStudent({required String studentId}) {
    return client.get('/students/$studentId');
  }

  /// `POST /students` — enrols a student (STU-001, `PERM-STUDENT-CREATE`).
  Future<ApiResponse> createStudent({
    required String schoolId,
    required String admissionNo,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? branchId,
    String? studentClassId,
    bool? transportEligible,
  }) {
    return client.post(
      '/students',
      body: {
        'schoolId': schoolId,
        'admissionNo': admissionNo,
        'firstName': firstName,
        'lastName': lastName,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (studentClassId != null && studentClassId.isNotEmpty) 'studentClassId': studentClassId,
        if (transportEligible != null) 'transportEligible': transportEligible,
      },
    );
  }

  /// `PATCH /students/{id}` — corrects details (STU-001, `PERM-STUDENT-EDIT`).
  ///
  /// `schoolId` and `admissionNo` are absent: moving a child between schools is a transfer with
  /// its own rule (BR-STU-006), and renumbering would break every safety record citing them.
  Future<ApiResponse> updateStudent({
    required String studentId,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? branchId,
    String? studentClassId,
    bool? transportEligible,
  }) {
    return client.patch(
      '/students/$studentId',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (studentClassId != null && studentClassId.isNotEmpty) 'studentClassId': studentClassId,
        if (transportEligible != null) 'transportEligible': transportEligible,
      },
    );
  }

  /// `POST /students/{id}/withdraw` — takes the student off the roll (STU-004,
  /// `PERM-STUDENT-EDIT`).
  ///
  /// Not a DELETE, because nothing is deleted: BR-STU-005 keeps the record for as long as any
  /// safety record references the child, which is forever in practice.
  Future<ApiResponse> withdrawStudent({required String studentId, String? reason}) {
    return client.post(
      '/students/$studentId/withdraw',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
  }
}
