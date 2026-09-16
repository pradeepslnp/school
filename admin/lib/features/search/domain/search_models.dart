import 'package:equatable/equatable.dart';

/// The kinds of record global search returns (SRC-001, `SEARCH_API.md`), in the order the
/// console lists them.
///
/// [unknown] exists because a newer server may add a kind this build cannot open. Such a group is
/// left out of the panel rather than shown without a label or a destination.
enum SearchResultType {
  student,
  guardian,
  staff,
  vehicle,
  route,
  user,
  school,
  organization,
  unknown;

  static SearchResultType fromWire(Object? wire) => switch (wire) {
        'STUDENT' => student,
        'GUARDIAN' => guardian,
        'STAFF' => staff,
        'VEHICLE' => vehicle,
        'ROUTE' => route,
        'USER' => user,
        'SCHOOL' => school,
        'ORGANIZATION' => organization,
        _ => unknown,
      };
}

/// Which field of a record the query matched.
///
/// Drives what the panel leads with: a phone number typed in comes back as that number with the
/// person it belongs to beneath it, not as a name the operator never typed.
enum SearchMatchedField {
  name,
  admissionNo,
  phone,
  email,
  employeeCode,
  registrationNo,
  code;

  /// Anything unrecognised reads as a name match, which only changes what the row leads with.
  static SearchMatchedField fromWire(Object? wire) => switch (wire) {
        'ADMISSION_NO' => admissionNo,
        'PHONE' => phone,
        'EMAIL' => email,
        'EMPLOYEE_CODE' => employeeCode,
        'REGISTRATION_NO' => registrationNo,
        'CODE' => code,
        _ => name,
      };
}

/// One record search found. Which optional field carries what depends on [type] — see
/// `SEARCH_API.md` §Result fields.
class SearchHit extends Equatable {
  const SearchHit({
    required this.type,
    required this.id,
    required this.title,
    required this.matchedField,
    required this.matchedValue,
    this.kind,
    this.code,
    this.status,
    this.schoolId,
    this.schoolName,
    this.relatedStudentId,
    this.relatedStudentName,
    this.organizationId,
    this.organizationName,
  });

  final SearchResultType type;
  final String id;

  /// The record's name — a person's full name, a vehicle's display name, a school's name.
  final String title;

  final SearchMatchedField matchedField;

  /// The value that matched: the name again, or the number or code that was typed.
  final String matchedValue;

  /// Staff type (`DRIVER`/`ATTENDANT`), role code, vehicle type, or region profile.
  final String? kind;

  /// Admission number, employee code, registration number, or route/school/organization code.
  final String? code;

  final String? status;
  final String? schoolId;
  final String? schoolName;

  /// For a parent, the linked child shown beside them — and the record their row opens.
  final String? relatedStudentId;
  final String? relatedStudentName;

  /// The organization the record belongs to — set only when a platform operator's search spans
  /// organizations (ADR-0018). Opening the result enters it.
  final String? organizationId;
  final String? organizationName;

  bool get matchedByName => matchedField == SearchMatchedField.name;

  @override
  List<Object?> get props => [
        type,
        id,
        title,
        matchedField,
        matchedValue,
        kind,
        code,
        status,
        schoolId,
        schoolName,
        relatedStudentId,
        relatedStudentName,
        organizationId,
        organizationName,
      ];
}

/// The results of one kind, capped by the server.
class SearchGroup extends Equatable {
  const SearchGroup({required this.type, required this.hits, required this.hasMore});

  final SearchResultType type;
  final List<SearchHit> hits;

  /// More of this kind matched than are shown — the operator narrows by typing more, not paging.
  final bool hasMore;

  @override
  List<Object?> get props => [type, hits, hasMore];
}

/// Everything one search found, grouped by kind.
class SearchResults extends Equatable {
  const SearchResults({required this.query, required this.groups});

  final String query;
  final List<SearchGroup> groups;

  bool get isEmpty => groups.every((group) => group.hits.isEmpty);

  @override
  List<Object?> get props => [query, groups];
}
