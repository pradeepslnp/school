import 'package:equatable/equatable.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Display name for a relationship code, shared by [GuardianTile] and [AddGuardianForm] — both
/// mapped these independently with a literal `Map<String, String>` before ADR-0013; unifying
/// them here is what keeps "Aunt / Uncle" from drifting into two different Kannada strings
/// later.
String guardianRelationshipLabel(AppLocalizations l10n, String relationshipType) =>
    switch (relationshipType) {
      'MOTHER' => l10n.guardianRelationshipMother,
      'FATHER' => l10n.guardianRelationshipFather,
      'GUARDIAN' => l10n.guardianRelationshipGuardian,
      'GRANDPARENT' => l10n.guardianRelationshipGrandparent,
      'AUNT_UNCLE' => l10n.guardianRelationshipAuntUncle,
      'OTHER' => l10n.guardianRelationshipOther,
      _ => relationshipType,
    };

/// A student's guardian as the enrolment screen reads it — the parent's own details joined
/// with the rights they hold on the link to this particular child. Returned by
/// `GET /students/{id}/guardians` and `POST /students/{id}/guardians` (GRD-001, GRD-002).
///
/// Rights are explicit fields, never inferred from [relationshipType]: "mother" grants
/// nothing by itself, exactly as the backend records it (BR-GRD-001). [canAuthoriseHandover]
/// is the consequential one — it is what lets this adult actually collect the child, and what
/// a student needs at least one of before being put on a bus (BR-GRD-002).
class StudentGuardian extends Equatable {
  const StudentGuardian({
    required this.linkId,
    required this.guardianId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.relationshipType,
    required this.canView,
    required this.canReceiveNotifications,
    required this.canAuthoriseHandover,
    required this.canDeclareAbsence,
    required this.isPrimary,
    required this.hasLogin,
    this.email,
  });

  final String linkId;
  final String guardianId;
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

  /// Whether this guardian has a working sign-in yet. Created immediately from their phone in
  /// this console's flow, so normally true — the field exists so a record imported without an
  /// account still reads honestly.
  final bool hasLogin;

  String get displayName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
        linkId,
        guardianId,
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
        hasLogin,
      ];
}
