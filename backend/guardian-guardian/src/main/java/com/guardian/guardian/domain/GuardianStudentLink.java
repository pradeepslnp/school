package com.guardian.guardian.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * The authorisation edge between a guardian and a student (MOD-04, {@code guardian_student_links}
 * 🔴 — "may this adult collect this child?").
 *
 * <p><strong>Rights are explicit booleans, never inferred from {@code relationshipType}.</strong>
 * {@code relationshipType} ("MOTHER", "UNCLE") is descriptive only and confers nothing. Custody
 * arrangements exist and a parent may be legally barred from collection (BR-GRD-008), so inferring
 * "father ⇒ may collect" would encode an assumption that is wrong in exactly the cases where being
 * wrong causes harm (BR-GRD-001 🔴).
 *
 * <p>{@code canAuthoriseHandover} is the consequential one: at least one active link per student
 * must carry it before that student can be put on a bus (BR-GRD-002 🔴), and a child must never
 * arrive at a drop stop with nobody authorised to receive them. That minimum is enforced where
 * links are removed or edited, not in this constructor, because it is a cross-row rule about a
 * student's whole set of guardians.
 */
public record GuardianStudentLink(
    UUID id,
    UUID guardianId,
    UUID studentId,
    String relationshipType,
    boolean canView,
    boolean canReceiveNotifications,
    boolean canAuthoriseHandover,
    boolean canDeclareAbsence,
    boolean isPrimary,
    boolean active) {

  public GuardianStudentLink {
    Objects.requireNonNull(guardianId, "guardianId");
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(relationshipType, "relationshipType");
  }
}
