package com.guardian.guardian.application.port;

import com.guardian.guardian.domain.Guardian;
import com.guardian.guardian.domain.GuardianStudentLink;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for guardian records and their links to students (MOD-04).
 *
 * <p>Every method is implicitly tenant-scoped: row-level security applies the {@code tenant_id}
 * predicate to every statement (ADR-0001), so tenant is absent from the SQL by design — repeating
 * it would imply the policy were optional.
 */
public interface GuardianRepository {

  /**
   * The guardian record tied to this login within the tenant, if any. Used to keep guardian
   * creation idempotent — a parent already on file (perhaps for a sibling) is reused, not
   * duplicated.
   */
  Optional<Guardian> findByUserId(UUID userId);

  Guardian saveGuardian(Guardian guardian, UUID actorUserId);

  /**
   * Creates the guardian↔student link, or reactivates and updates it if one already exists for this
   * pair (the {@code uq_guardian_student} constraint makes the pair unique). Returns the stored
   * link with its id.
   */
  GuardianStudentLink saveLink(GuardianStudentLink link, UUID actorUserId);

  /** Every active guardian of a student, with the rights held on each link — for the enrolment
   * screen (GRD-002). Primary guardian first. */
  List<StudentGuardian> findActiveForStudent(UUID studentId);

  /**
   * BR-STU-002 as a lookup: does this student have at least one active guardian holding
   * {@code can_authorise_handover}? Asked by route assignment through the routes module's
   * {@code StudentGuardianGuard} before a student may be put on a bus.
   */
  boolean hasActiveHandoverGuardian(UUID studentId);

  /**
   * A student's guardian as the enrolment screen reads it: the guardian's own details joined with
   * the rights held on the link to this particular student. A read projection, not an aggregate —
   * it spans two tables and is never written back through.
   */
  record StudentGuardian(
      UUID linkId,
      UUID guardianId,
      UUID userId,
      String firstName,
      String lastName,
      String phone,
      String email,
      String relationshipType,
      boolean canView,
      boolean canReceiveNotifications,
      boolean canAuthoriseHandover,
      boolean canDeclareAbsence,
      boolean isPrimary) {

    public boolean hasLogin() {
      return userId != null;
    }
  }
}
