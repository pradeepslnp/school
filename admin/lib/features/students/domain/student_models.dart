import 'package:equatable/equatable.dart';

/// A student as returned by `POST /students`, `GET /students`, and `GET /students/{id}`
/// (STU-001). Contract: `STUDENTS_GUARDIANS_API.md` §Students.
///
/// There is no `photoRef` here, and there must not be. The backend deliberately withholds it:
/// it is a storage key, and a client that held one would be one step from building a URL out
/// of it. Photos come from `GET /students/{id}/photo`, which checks permission and scope on
/// every request. [hasPhoto] is all a list row needs to know.
class Student extends Equatable {
  const Student({
    required this.id,
    required this.schoolId,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    required this.enrolmentStatus,
    required this.transportEligible,
    required this.hasPhoto,
    this.branchId,
    this.studentClassId,
    this.dateOfBirth,
  });

  final String id;
  final String schoolId;
  final String? branchId;
  final String? studentClassId;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String enrolmentStatus;
  final bool transportEligible;
  final bool hasPhoto;

  String get displayName => '$firstName $lastName'.trim();

  /// BR-STU-004: only an active student may be put on a route or a manifest, and only if the
  /// family has not opted out of transport. Both conditions, not either.
  bool get isAssignable => enrolmentStatus == 'ACTIVE' && transportEligible;

  bool get isWithdrawn => enrolmentStatus == 'WITHDRAWN';

  @override
  List<Object?> get props => [
        id,
        schoolId,
        branchId,
        studentClassId,
        admissionNo,
        firstName,
        lastName,
        dateOfBirth,
        enrolmentStatus,
        transportEligible,
        hasPhoto,
      ];
}

/// One page of the register, with the cursor that reaches the next.
///
/// [nextCursor] is null on the last page. It is opaque to this client by contract — the
/// console passes back whatever the API gave it rather than deriving the next position
/// itself, so the paging key can change server-side without a client release.
class StudentPage extends Equatable {
  const StudentPage({required this.students, this.nextCursor});

  final List<Student> students;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [students, nextCursor];
}
