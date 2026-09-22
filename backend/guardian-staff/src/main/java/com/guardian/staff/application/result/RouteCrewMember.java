package com.guardian.staff.application.result;

import com.guardian.staff.domain.DutyAssignmentId;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import java.time.LocalDate;
import java.util.Optional;

/**
 * One member of a route's standing crew, as the Routes screen reads it (feature STF-004, screen
 * A-25): the duty assignment joined with the person holding it.
 *
 * <p>The name is here because a roster of ids answers nothing — an operator replacing an absent
 * driver has to see who is on the route. Both tables belong to MOD-06, so this is a projection
 * within one module, not a cross-module read.
 *
 * @param direction empty when the crew member runs both directions
 */
public record RouteCrewMember(
    DutyAssignmentId id,
    StaffId staffId,
    RouteId routeId,
    String firstName,
    String lastName,
    StaffType role,
    Optional<String> direction,
    LocalDate effectiveFrom,
    Optional<LocalDate> effectiveUntil,
    boolean active) {}
