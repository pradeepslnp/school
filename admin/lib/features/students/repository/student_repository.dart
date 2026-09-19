import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/student_data_provider.dart';
import '../domain/student_models.dart';

/// Turns student transport into domain outcomes.
///
/// The bloc depends on this, never on [StudentDataProvider] directly — matching
/// [StaffRepository], so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class StudentRepository {
  StudentRepository({required this.dataProvider});

  final StudentDataProvider dataProvider;

  Future<Result<StudentPage>> listStudents({
    required String schoolId,
    String? cursor,
    int? limit,
  }) async {
    final response = await dataProvider.listStudents(
      schoolId: schoolId,
      cursor: cursor,
      limit: limit,
    );
    if (!response.isSuccess) return _toFailure<StudentPage>(response);

    final students = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseStudent)
        .whereType<Student>()
        .toList(growable: false);

    return Success<StudentPage>(
      StudentPage(students: students, nextCursor: response.nextCursor),
    );
  }

  Future<Result<Student>> getStudent({required String studentId}) async {
    final response = await dataProvider.getStudent(studentId: studentId);
    return _single(response);
  }

  Future<Result<Student>> createStudent({
    required String schoolId,
    required String admissionNo,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? branchId,
    String? studentClassId,
    bool? transportEligible,
  }) async {
    final response = await dataProvider.createStudent(
      schoolId: schoolId,
      admissionNo: admissionNo.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      dateOfBirth: dateOfBirth,
      branchId: branchId,
      studentClassId: studentClassId,
      transportEligible: transportEligible,
    );
    return _single(response);
  }

  Future<Result<Student>> updateStudent({
    required String studentId,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? branchId,
    String? studentClassId,
    bool? transportEligible,
  }) async {
    final response = await dataProvider.updateStudent(
      studentId: studentId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      dateOfBirth: dateOfBirth,
      branchId: branchId,
      studentClassId: studentClassId,
      transportEligible: transportEligible,
    );
    return _single(response);
  }

  Future<Result<Student>> withdrawStudent({
    required String studentId,
    String? reason,
  }) async {
    final response = await dataProvider.withdrawStudent(
      studentId: studentId,
      reason: reason?.trim(),
    );
    return _single(response);
  }

  /// Nothing comes back on success — the student no longer exists.
  Future<Result<void>> discardStudent({
    required String studentId,
    required String reason,
  }) async {
    final response = await dataProvider.discardStudent(
      studentId: studentId,
      reason: reason.trim(),
    );
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  Result<Student> _single(ApiResponse response) {
    if (!response.isSuccess) return _toFailure<Student>(response);

    final student = _parseStudent(response.data);
    if (student == null) {
      // A 2xx we cannot read is a contract breach, not a validation problem — matching
      // StaffRepository's treatment of the same case.
      return const Failure<Student>(ErrorCode.internalError);
    }
    return Success<Student>(student);
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

  Student? _parseStudent(Map<String, Object?> data) {
    final id = data['id'];
    final schoolId = data['schoolId'];
    final admissionNo = data['admissionNo'];
    final firstName = data['firstName'];
    final lastName = data['lastName'];
    final enrolmentStatus = data['enrolmentStatus'];
    final transportEligible = data['transportEligible'];
    final hasPhoto = data['hasPhoto'];
    if (id is! String ||
        schoolId is! String ||
        admissionNo is! String ||
        firstName is! String ||
        lastName is! String ||
        enrolmentStatus is! String ||
        transportEligible is! bool ||
        hasPhoto is! bool) {
      return null;
    }
    return Student(
      id: id,
      schoolId: schoolId,
      branchId: data['branchId'] as String?,
      studentClassId: data['studentClassId'] as String?,
      admissionNo: admissionNo,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: _parseDate(data['dateOfBirth']),
      enrolmentStatus: enrolmentStatus,
      transportEligible: transportEligible,
      hasPhoto: hasPhoto,
    );
  }

  /// A malformed date is dropped rather than failing the whole row: a date of birth is not
  /// what identifies the student, and refusing to show a child because one field is unreadable
  /// would hide them from the register entirely.
  DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
