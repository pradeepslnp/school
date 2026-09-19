import 'package:equatable/equatable.dart';

/// What the operator did on the Drivers screen (A-23).
sealed class StaffListEvent extends Equatable {
  const StaffListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown, or the operator asked to refresh, for one school's roster.
final class StaffListRequested extends StaffListEvent {
  const StaffListRequested({required this.schoolId});

  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}

/// The operator registered a new driver or attendant (STF-001).
///
/// No `code` field beyond `employeeCode`, which is optional — unlike an organization or school
/// code, an employee code is not this record's identity, just an operational label
/// (`CreateTransportStaffUseCase` does not treat it as one either).
final class StaffCreated extends StaffListEvent {
  const StaffCreated({
    required this.schoolId,
    required this.staffType,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.employeeCode,
    this.vendorName,
  });

  final String schoolId;
  final String staffType;
  final String firstName;
  final String lastName;
  final String phone;
  final String? employeeCode;
  final String? vendorName;

  @override
  List<Object?> get props =>
      [schoolId, staffType, firstName, lastName, phone, employeeCode, vendorName];
}

/// The operator saved changes to an existing driver or attendant's details from the edit
/// dialog (STF-001). `staffType` and `schoolId` are absent — see
/// `UpdateTransportStaffUseCase`'s own documentation for why a type change is not offered as
/// an edit.
final class StaffUpdated extends StaffListEvent {
  const StaffUpdated({
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.employeeCode,
    this.vendorName,
  });

  final String staffId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? employeeCode;
  final String? vendorName;

  @override
  List<Object?> get props =>
      [staffId, firstName, lastName, phone, employeeCode, vendorName];
}

/// The operator deleted a driver or attendant entered by mistake (STF-007, ADR-0019). Confirmed
/// in the UI with a required reason first — this cannot be undone.
final class StaffDiscarded extends StaffListEvent {
  const StaffDiscarded({required this.staffId, required this.reason});

  final String staffId;
  final String reason;

  @override
  List<Object?> get props => [staffId, reason];
}
