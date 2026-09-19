import 'package:equatable/equatable.dart';

/// What the operator did on a student's guardians panel (A-11).
sealed class StudentGuardiansEvent extends Equatable {
  const StudentGuardiansEvent();

  @override
  List<Object?> get props => const [];
}

/// The panel was opened for a student, or the operator asked to refresh it.
final class StudentGuardiansRequested extends StudentGuardiansEvent {
  const StudentGuardiansRequested({required this.studentId});

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}

/// The operator added a parent to this student.
final class GuardianAdded extends StudentGuardiansEvent {
  const GuardianAdded({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.relationshipType,
    required this.canView,
    required this.canReceiveNotifications,
    required this.canAuthoriseHandover,
    required this.canDeclareAbsence,
    required this.isPrimary,
  });

  final String studentId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String relationshipType;
  final bool canView;
  final bool canReceiveNotifications;
  final bool canAuthoriseHandover;
  final bool canDeclareAbsence;
  final bool isPrimary;

  @override
  List<Object?> get props => [
        studentId,
        firstName,
        lastName,
        phone,
        email,
        relationshipType,
        canView,
        canReceiveNotifications,
        canAuthoriseHandover,
        canDeclareAbsence,
        isPrimary,
      ];
}

/// The operator corrected a parent's name, phone, or email (GRD-001). A changed phone moves the
/// parent's sign-in to the new number (BR-IAM-014) — the form says so before saving.
final class GuardianUpdated extends StudentGuardiansEvent {
  const GuardianUpdated({
    required this.studentId,
    required this.guardianId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
  });

  /// The student whose panel is open, to re-list after the save.
  final String studentId;
  final String guardianId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;

  @override
  List<Object?> get props => [studentId, guardianId, firstName, lastName, phone, email];
}
