package com.guardian.staff.interfaces.rest.dto;

import com.guardian.staff.domain.DutyAssignment;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Wire representation of a duty assignment. A domain object is never serialised directly to a
 * client.
 */
public record DutyAssignmentResponse(
    UUID id,
    UUID staffId,
    UUID routeId,
    String role,
    String direction,
    LocalDate effectiveFrom,
    LocalDate effectiveUntil,
    boolean active) {

  public static DutyAssignmentResponse from(DutyAssignment assignment) {
    return new DutyAssignmentResponse(
        assignment.id().value(),
        assignment.staffId().value(),
        assignment.routeId().value(),
        assignment.role().name(),
        assignment.direction().map(Enum::name).orElse(null),
        assignment.effectiveFrom(),
        assignment.effectiveUntil().orElse(null),
        assignment.active());
  }
}
