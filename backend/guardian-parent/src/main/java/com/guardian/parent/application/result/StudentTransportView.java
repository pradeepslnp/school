package com.guardian.parent.application.result;

import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * The bus and crew a student is assigned to, per direction, as school staff read it on the student
 * record (feature STU-009, screen A-11, ADR-0020).
 *
 * <p>This is the <em>plan</em>: the route the child is assigned to, that route's default bus, and
 * the driver and attendant on duty for it today. It is never evidence of where the child is — that
 * comes from boarding events on a running trip, and a trip may run with a substitute bus or crew.
 * The console labels it "assigned" for exactly that reason.
 *
 * @param legs one per direction the student is assigned for, pickup first; empty when the student
 *     has no route assignment
 */
public record StudentTransportView(UUID studentId, UUID schoolId, List<Leg> legs) {

  public StudentTransportView {
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(schoolId, "schoolId");
    legs = List.copyOf(legs);
  }

  /**
   * One direction of the student's assigned transport.
   *
   * @param vehicle the route's default bus, or null when the route has none set
   * @param crew the driver(s) and attendant(s) on duty for this route and direction today; empty
   *     when none is assigned
   */
  public record Leg(
      String direction,
      UUID routeId,
      String routeCode,
      String routeName,
      UUID stopId,
      String stopName,
      Vehicle vehicle,
      List<CrewMember> crew) {

    public Leg {
      Objects.requireNonNull(direction, "direction");
      crew = List.copyOf(crew);
    }
  }

  /** A bus as the office recognises it: its registration and the name painted on it. */
  public record Vehicle(UUID id, String registrationNo, String displayName, String status) {}

  /**
   * A driver or attendant, by name only. Their phone stays on the Drivers screen, behind {@code
   * PERM-STAFF-VIEW}, rather than being copied onto every student record.
   */
  public record CrewMember(UUID staffId, String role, String firstName, String lastName) {}
}
