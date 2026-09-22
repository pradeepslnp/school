package com.guardian.staff.interfaces.rest.dto;

import com.guardian.staff.application.result.RouteCrewMember;
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
    // Who holds the duty. A roster of ids cannot be read by the person replacing an absent driver.
    String staffFirstName,
    String staffLastName,
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
        null,
        null,
        assignment.routeId().value(),
        assignment.role().name(),
        assignment.direction().map(Enum::name).orElse(null),
        assignment.effectiveFrom(),
        assignment.effectiveUntil().orElse(null),
        assignment.active());
  }

  /** A route's crew row, name included (screen A-25). */
  public static DutyAssignmentResponse from(RouteCrewMember member) {
    return new DutyAssignmentResponse(
        member.id().value(),
        member.staffId().value(),
        member.firstName(),
        member.lastName(),
        member.routeId().value(),
        member.role().name(),
        member.direction().orElse(null),
        member.effectiveFrom(),
        member.effectiveUntil().orElse(null),
        member.active());
  }
}
