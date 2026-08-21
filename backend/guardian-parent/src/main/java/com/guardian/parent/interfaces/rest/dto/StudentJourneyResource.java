package com.guardian.parent.interfaces.rest.dto;

import com.guardian.parent.domain.ChildJourney;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * One student in the {@code data} array of {@code GET /guardians/me/students}.
 *
 * <p>Shape is fixed by guardian-docs/04-api/STUDENTS_GUARDIANS_API.md — {@code id} / {@code type} /
 * {@code attributes}, with journey state nested under {@code attributes.journey}. The parent app
 * parses exactly this, so the record below is the contract rather than a convenience.
 *
 * <p>Null fields are omitted on the wire ({@code default-property-inclusion: non_null}), which is
 * what the API standard asks for: absent means unknown, never {@code ""} or {@code 0}.
 */
public record StudentJourneyResource(UUID id, String type, Map<String, Object> attributes) {

  public static StudentJourneyResource from(ChildJourney child) {
    Map<String, Object> journey = new LinkedHashMap<>();
    journey.put("state", child.state().wireName());
    putIfPresent(journey, "tripId", child.tripId());
    putIfPresent(journey, "vehicleDisplayName", child.vehicleDisplayName());
    putIfPresent(journey, "stopName", child.stopName());
    putIfPresent(journey, "lastEventAt", iso(child.lastEventAt()));
    putIfPresent(journey, "estimatedArrival", iso(child.estimatedArrival()));
    putIfPresent(journey, "nextDepartureAt", iso(child.nextDepartureAt()));
    putIfPresent(journey, "positionReceivedAt", iso(child.positionReceivedAt()));
    // Always present when tracking applies (BR-TRACK-003): the client must never have to infer
    // staleness from a missing field.
    if (child.state().permitsLiveTracking()) {
      journey.put("isPositionStale", child.positionStale() == null || child.positionStale());
    }

    Map<String, Object> attributes = new LinkedHashMap<>();
    attributes.put("displayName", child.displayName());
    putIfPresent(attributes, "className", child.className());
    attributes.put("journey", journey);

    return new StudentJourneyResource(child.studentId(), "student", attributes);
  }

  private static void putIfPresent(Map<String, Object> target, String key, Object value) {
    if (value != null) {
      target.put(key, value);
    }
  }

  /** UTC with {@code Z}, per guardian-docs/04-api/API_STANDARDS.md. */
  private static String iso(Instant value) {
    return value == null ? null : value.toString();
  }
}
