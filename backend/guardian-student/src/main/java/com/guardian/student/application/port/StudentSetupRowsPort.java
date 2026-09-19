package com.guardian.student.application.port;

import com.guardian.student.domain.StudentId;

/**
 * Removes the setup rows other modules hold for a student being discarded (feature STU-008,
 * BR-STU-007, ADR-0019): the student's guardian links (MOD-04) and route assignments (MOD-07).
 *
 * <p>Both modules sit above this one (MODULE_MAP rule 3), so this module cannot call them and must
 * not touch their tables. The port lives here and the adapter in the composition root, the same
 * dependency-inversion shape as {@code StudentGuardianGuard} in the routes module.
 *
 * <p>Runs inside the discard's own transaction. Nothing here decides whether a discard is allowed —
 * the {@code RESTRICT} foreign keys on every other table do that when the student row itself is
 * deleted, and a refusal there rolls these deletions back too.
 */
public interface StudentSetupRowsPort {

  /**
   * Deletes every link, active or not, between the student and a guardian. Guardian records
   * themselves are kept: they may belong to a sibling.
   *
   * @return how many were removed
   */
  int deleteGuardianLinks(StudentId studentId);

  /**
   * Deletes every route assignment, active or not, held by the student.
   *
   * @return how many were removed
   */
  int deleteRouteAssignments(StudentId studentId);
}
