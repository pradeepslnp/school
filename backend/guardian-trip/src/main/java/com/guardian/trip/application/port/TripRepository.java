package com.guardian.trip.application.port;

import com.guardian.trip.domain.ScheduledRun;
import com.guardian.trip.domain.Trip;
import com.guardian.trip.domain.TripStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for {@code trips} (MOD-08).
 *
 * <p>A domain-facing interface in the application layer, implemented in infrastructure — the
 * repository pattern this codebase applies everywhere (ENGINEERING_PRINCIPLES.md §Repository).
 *
 * <p>Every method runs under row-level security, so no method takes a tenant id. One that did
 * would suggest the policy were optional.
 */
public interface TripRepository {

  /**
   * Inserts a {@code SCHEDULED} trip for each run that does not already have one.
   *
   * <p>Idempotent by construction: {@code uq_trips_route_date_direction} makes a second insert for
   * the same route, date and direction a conflict, and the adapter swallows it. That is what lets
   * the nightly job, an operator's manual trigger, and two application instances all run
   * generation for the same date without coordination or a distributed lock.
   *
   * @return how many trips were actually created, for the job's log line.
   */
  int createScheduled(List<ScheduledRun> runs, LocalDate serviceDate, UUID actorUserId);

  Optional<Trip> findById(UUID tripId);

  /** Today's runs for one school, newest scheduled time last. Used by the crew's day view. */
  List<Trip> findBySchoolAndDate(UUID schoolId, LocalDate serviceDate);

  /**
   * The trips the given staff member is crewed for on a date, with the context the app needs.
   *
   * <p>Resolved through {@code duty_assignments} — the standing roster — rather than through a
   * per-trip crew table, which does not exist yet (V13 notes the same thing). A driver opening the
   * app sees the runs their roster says they are on.
   */
  List<CrewTrip> findForStaffOnDate(UUID staffId, LocalDate serviceDate);

  /**
   * Moves a trip to {@code IN_PROGRESS}, recording the vehicle and both clocks.
   *
   * <p>Guarded by the expected current status in the {@code WHERE} clause, so two crew members
   * tapping "start" at the same moment produce one start and one refusal rather than two starts —
   * the check-then-act race a service-layer guard alone cannot close.
   *
   * @return true if this call performed the transition.
   */
  boolean start(UUID tripId, UUID vehicleId, Instant startedAt, Instant deviceStartedAt);

  /**
   * Moves a trip between statuses, guarded by its expected current status.
   *
   * @return true if this call performed the transition.
   */
  boolean transition(UUID tripId, TripStatus from, TripStatus to, Instant at, String reason);

  /** Whether the vehicle is already out on an {@code IN_PROGRESS} trip (BR-TRIP-005). */
  boolean vehicleIsOnAnotherTrip(UUID vehicleId, UUID excludingTripId);

  /** Whether the staff member is already crewed on an {@code IN_PROGRESS} trip (BR-TRIP-005). */
  boolean staffIsOnAnotherTrip(UUID staffId, UUID excludingTripId);

  /** Whether the staff member is on the standing roster for this trip's route (BR-TRIP-006). */
  boolean isRosteredCrewFor(UUID tripId, UUID staffId);
}
