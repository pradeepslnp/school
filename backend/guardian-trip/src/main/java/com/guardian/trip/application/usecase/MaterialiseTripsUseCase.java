package com.guardian.trip.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.trip.application.port.RouteTimetableReadModel;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.ScheduledRun;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Creates the {@code SCHEDULED} trips a service date should have (BR-TRIP-011).
 *
 * <p>This is the use case that closed the platform's largest gap: until it existed nothing created
 * a trip row, so every safety record that anchors to a trip had nothing to anchor to, and the
 * parent app's journey state was permanently {@code AT_REST} outside the demo seed.
 *
 * <p><strong>Idempotent, deliberately and at the database.</strong> {@code
 * uq_trips_route_date_direction} rejects a duplicate, and the adapter's {@code ON CONFLICT DO
 * NOTHING} turns that into a no-op. Three callers rely on this and none of them coordinates with
 * the others: the nightly job, an operator triggering generation by hand after fixing a timetable,
 * and a second application instance running the same job at the same instant. Making generation
 * safe to repeat is what removes the need for a distributed lock — the cheaper correctness.
 *
 * <p>It does <strong>not</strong> touch trips that already exist. A run cancelled by a transport
 * manager stays cancelled when the job next runs; re-creating it would silently undo a human
 * decision.
 */
@Service
public class MaterialiseTripsUseCase {

  private final RouteTimetableReadModel timetable;
  private final TripRepository trips;

  public MaterialiseTripsUseCase(RouteTimetableReadModel timetable, TripRepository trips) {
    this.timetable = timetable;
    this.trips = trips;
  }

  /**
   * Generates for one date, in the tenant currently in context.
   *
   * @param actorUserId the operator who triggered it, or null when the scheduled job did. Null is
   *     honest here: inventing a system user id would make an automated action indistinguishable
   *     from a person's in {@code created_by}.
   * @return how many trips were created — zero being the normal result on a holiday, or on a
   *     second run for the same date.
   */
  @Transactional
  @BusinessRule({"BR-TRIP-001", "BR-TRIP-011"})
  public int execute(LocalDate serviceDate, UUID actorUserId) {
    List<ScheduledRun> runs = timetable.runsFor(serviceDate);
    if (runs.isEmpty()) {
      return 0;
    }
    return trips.createScheduled(runs, serviceDate, actorUserId);
  }
}
