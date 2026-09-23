package com.guardian.trip.domain;

import java.time.LocalTime;
import java.util.Objects;
import java.util.UUID;

/**
 * One run that a route's timetable says should happen: a route, a direction, and the time the first
 * stop expects the bus.
 *
 * <p>Derived, never stored. The timetable already lives on {@code stops} — a route runs a PICKUP
 * exactly when one of its active stops carries a {@code scheduled_pickup_time}, and the run starts
 * at the earliest of them. Recording a second copy on the route would be a second version of the
 * same fact, and the first symptom of the two disagreeing would be a bus arriving when nobody is
 * waiting.
 *
 * @param scheduledStartTime the earliest scheduled stop time on this run, in the school's wall
 *     clock. Never null — a run with no timed stop is not a run, and the read model does not
 *     produce one.
 */
public record ScheduledRun(
    UUID routeId, UUID schoolId, TripDirection direction, LocalTime scheduledStartTime) {

  public ScheduledRun {
    Objects.requireNonNull(routeId, "routeId");
    Objects.requireNonNull(schoolId, "schoolId");
    Objects.requireNonNull(direction, "direction");
    Objects.requireNonNull(scheduledStartTime, "scheduledStartTime");
  }
}
