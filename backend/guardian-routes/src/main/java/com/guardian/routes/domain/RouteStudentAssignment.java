package com.guardian.routes.domain;

import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Which student boards which route, at which stop, in which direction (MOD-07, {@code
 * route_student_assignments}, feature RTE-003).
 *
 * <p>A student holds at most one active {@code PICKUP} and one active {@code DROP} — enforced
 * structurally by {@code uq_rsa_student_direction} (BR-ROUTE-004), because two active pickups would
 * put one child on two manifests and make the wrong-vehicle safety control fire on a legitimate
 * boarding. Pickup and drop may be on different routes (BR-ROUTE-005), which is why the uniqueness
 * is on {@code (student, direction)} and never on the route.
 *
 * <p>{@code direction} is a plain string checked against the two legal values here and by the
 * database's own {@code ck_rsa_direction} constraint — the same two-sided guard the rest of this
 * codebase uses where a small closed set is also a database CHECK.
 */
public record RouteStudentAssignment(
    UUID id,
    UUID routeId,
    UUID stopId,
    UUID studentId,
    String direction,
    LocalDate validFrom,
    LocalDate validTo,
    boolean active) {

  public static final String PICKUP = "PICKUP";
  public static final String DROP = "DROP";

  public RouteStudentAssignment {
    Objects.requireNonNull(routeId, "routeId");
    Objects.requireNonNull(stopId, "stopId");
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(direction, "direction");
    if (!direction.equals(PICKUP) && !direction.equals(DROP)) {
      throw new IllegalArgumentException("direction must be PICKUP or DROP");
    }
  }
}
