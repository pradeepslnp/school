package com.guardian.trip.application.port;

import com.guardian.trip.domain.ScheduledRun;
import java.time.LocalDate;
import java.util.List;

/**
 * Reads the timetable that says which runs should exist on a date (MOD-07's data, MOD-08's
 * question).
 *
 * <p>A read port rather than a call into MOD-07's Java: MOD-08 needs a projection across routes,
 * stops and the school calendar that no MOD-07 use case has any reason to expose, and a synchronous
 * dependency from Trip to Routes would add an edge the module graph does not currently have
 * (MODULE_MAP.md). The same reasoning ADR-0010 applies to MOD-18.
 */
public interface RouteTimetableReadModel {

  /**
   * Every run the timetable expects on {@code serviceDate}, for the tenant in context.
   *
   * <p>Applies all of BR-TRIP-011 in one query: the route is active, the weekday is in its
   * operating days (or the school has declared the date a working day), the school has not declared
   * it a holiday, and the run has at least one active stop with a scheduled time for that
   * direction. A route with no timed stops produces no run rather than a run at midnight.
   */
  List<ScheduledRun> runsFor(LocalDate serviceDate);
}
