import 'package:equatable/equatable.dart';

/// A transport staff member — driver or attendant — as returned by `POST /transport-staff` or
/// `GET /transport-staff` (STF-001).
///
/// [userId] is what actually determines whether this person can sign in to the driver app —
/// see `CreateTransportStaffUseCase` on the backend. It should never be null for a record this
/// console created, now that creation provisions the login in the same request; it stays
/// nullable here only because the wire contract itself allows it (a record created outside this
/// console, before that provisioning existed, could still have it unset).
class CreatedStaff extends Equatable {
  const CreatedStaff({
    required this.id,
    required this.schoolId,
    required this.staffType,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.verificationStatus,
    required this.active,
    this.userId,
    this.employeeCode,
    this.vendorName,
  });

  final String id;
  final String schoolId;
  final String? userId;
  final String staffType;
  final String? employeeCode;
  final String firstName;
  final String lastName;
  final String phone;
  final String? vendorName;
  final String verificationStatus;
  final bool active;

  String get displayName => '$firstName $lastName'.trim();

  bool get hasLogin => userId != null;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        userId,
        staffType,
        employeeCode,
        firstName,
        lastName,
        phone,
        vendorName,
        verificationStatus,
        active,
      ];
}
