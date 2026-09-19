package com.guardian.parent.interfaces.rest.dto;

import com.guardian.parent.application.result.StudentTransportView;
import java.util.List;
import java.util.UUID;

/**
 * Wire form of {@code GET /students/{studentId}/transport} (feature STU-009). Mirrors {@link
 * StudentTransportView} so the application result can change shape without changing the contract.
 */
public record StudentTransportResource(UUID studentId, UUID schoolId, List<LegResource> legs) {

  public static StudentTransportResource from(StudentTransportView view) {
    return new StudentTransportResource(
        view.studentId(), view.schoolId(), view.legs().stream().map(LegResource::from).toList());
  }

  /** One direction; {@code vehicle} is null when the route has no default bus set. */
  public record LegResource(
      String direction,
      UUID routeId,
      String routeCode,
      String routeName,
      UUID stopId,
      String stopName,
      VehicleResource vehicle,
      List<CrewResource> crew) {

    static LegResource from(StudentTransportView.Leg leg) {
      StudentTransportView.Vehicle vehicle = leg.vehicle();
      return new LegResource(
          leg.direction(),
          leg.routeId(),
          leg.routeCode(),
          leg.routeName(),
          leg.stopId(),
          leg.stopName(),
          vehicle == null
              ? null
              : new VehicleResource(
                  vehicle.id(), vehicle.registrationNo(), vehicle.displayName(), vehicle.status()),
          leg.crew().stream()
              .map(
                  member ->
                      new CrewResource(
                          member.staffId(), member.role(), member.firstName(), member.lastName()))
              .toList());
    }
  }

  public record VehicleResource(
      UUID id, String registrationNo, String displayName, String status) {}

  public record CrewResource(UUID staffId, String role, String firstName, String lastName) {}
}
