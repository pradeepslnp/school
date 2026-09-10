import 'package:equatable/equatable.dart';

/// What the operator did on the custody-restrictions panel (A-14).
sealed class StudentCustodyEvent extends Equatable {
  const StudentCustodyEvent();

  @override
  List<Object?> get props => const [];
}

/// The panel was shown, or a refresh was asked for.
final class StudentCustodyRequested extends StudentCustodyEvent {
  const StudentCustodyRequested({required this.studentId});

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}

/// The operator recorded a new restriction. Exactly one subject is set.
final class CustodyRestrictionRecorded extends StudentCustodyEvent {
  const CustodyRestrictionRecorded({
    required this.studentId,
    this.restrictedGuardianId,
    this.restrictedPersonName,
    required this.restrictionType,
    required this.reason,
    this.effectiveUntil,
  });

  final String studentId;
  final String? restrictedGuardianId;
  final String? restrictedPersonName;
  final String restrictionType;
  final String reason;
  final String? effectiveUntil;

  @override
  List<Object?> get props => [
        studentId,
        restrictedGuardianId,
        restrictedPersonName,
        restrictionType,
        reason,
        effectiveUntil,
      ];
}

/// The operator lifted a restriction.
final class CustodyRestrictionLifted extends StudentCustodyEvent {
  const CustodyRestrictionLifted({
    required this.studentId,
    required this.restrictionId,
  });

  final String studentId;
  final String restrictionId;

  @override
  List<Object?> get props => [studentId, restrictionId];
}
