package com.guardian.routes.application.port;

import java.util.UUID;

/**
 * Answers the one question route assignment must ask about a student's guardians without reaching
 * into the guardian bounded context directly: does this student have at least one active guardian
 * authorised to receive them?
 *
 * <p>Defined here and implemented in the composition root (guardian-api), the same dependency-
 * inversion shape as {@code StaffAccountProvisioningPort}. This module owns "may a student be
 * assigned to a route"; whether the guardian condition holds is a fact from MOD-04 that it asks for
 * through this narrow port rather than by querying another module's tables.
 */
public interface StudentGuardianGuard {

  /**
   * BR-STU-002 🔴 as a question: at least one active {@code guardian_student_links} row for this
   * student carries {@code can_authorise_handover}. False means the child must not be put on a bus
   * yet — nobody is authorised to collect them at the other end.
   */
  boolean hasActiveHandoverGuardian(UUID studentId);
}
