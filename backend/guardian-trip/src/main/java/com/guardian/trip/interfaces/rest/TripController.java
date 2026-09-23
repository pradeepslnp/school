package com.guardian.trip.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.trip.application.command.StartTripCommand;
import com.guardian.trip.application.usecase.CancelTripUseCase;
import com.guardian.trip.application.usecase.CompleteTripUseCase;
import com.guardian.trip.application.usecase.ListTripsUseCase;
import com.guardian.trip.application.usecase.MaterialiseTripsUseCase;
import com.guardian.trip.application.usecase.StartTripUseCase;
import com.guardian.trip.interfaces.rest.dto.CancelTripRequest;
import com.guardian.trip.interfaces.rest.dto.CrewTripResponse;
import com.guardian.trip.interfaces.rest.dto.StartTripRequest;
import com.guardian.trip.interfaces.rest.dto.TripGenerationResponse;
import com.guardian.trip.interfaces.rest.dto.TripResponse;
import jakarta.validation.Valid;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Trip endpoints (MOD-08). See documentation/04-api/TRIPS_BOARDING_API.md.
 *
 * <p>Translation only: parse the wire format, call one use case, map back. Every rule — who may
 * start which run, what a manifest contains, which transitions are legal — lives in the use cases,
 * because a rule enforced in a controller is a rule the next caller can bypass.
 *
 * <p><strong>There is deliberately no {@code /close} endpoint.</strong> BR-TRIP-009 makes closing
 * conditional on trip-close reconciliation (BR-SAFE-001 🔴), which belongs to MOD-09 and is not
 * built. Shipping a close that moved the status without reconciling would be a safety claim the
 * platform cannot honour.
 */
@RestController
@RequestMapping("/api/v1/trips")
public class TripController {

  private final ListTripsUseCase listTrips;
  private final StartTripUseCase startTrip;
  private final CompleteTripUseCase completeTrip;
  private final CancelTripUseCase cancelTrip;
  private final MaterialiseTripsUseCase materialiseTrips;
  private final Clock clock;

  public TripController(
      ListTripsUseCase listTrips,
      StartTripUseCase startTrip,
      CompleteTripUseCase completeTrip,
      CancelTripUseCase cancelTrip,
      MaterialiseTripsUseCase materialiseTrips,
      Clock clock) {
    this.listTrips = listTrips;
    this.startTrip = startTrip;
    this.completeTrip = completeTrip;
    this.cancelTrip = cancelTrip;
    this.materialiseTrips = materialiseTrips;
    this.clock = clock;
  }

  /** A school's runs for a date — the transport manager's day view. */
  @GetMapping
  @RequiresPermission("PERM-TRIP-VIEW")
  public List<TripResponse> list(
      @RequestParam UUID schoolId,
      @RequestParam(required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate serviceDate) {

    LocalDate date = serviceDate == null ? LocalDate.now(clock) : serviceDate;
    return listTrips.forSchool(schoolId, date).stream().map(TripResponse::from).toList();
  }

  /**
   * The calling crew member's own runs.
   *
   * <p>Takes no identifier of any kind — the use case resolves the caller's staff record itself.
   */
  @GetMapping("/mine")
  @RequiresPermission("PERM-TRIP-VIEW")
  public List<CrewTripResponse> mine(
      @RequestParam(required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate serviceDate,
      CurrentActor actor) {

    LocalDate date = serviceDate == null ? LocalDate.now(clock) : serviceDate;
    return listTrips.forCallingCrew(actor.userId(), date).stream()
        .map(CrewTripResponse::from)
        .toList();
  }

  @PostMapping("/{tripId}/start")
  @RequiresPermission("PERM-TRIP-START")
  public TripResponse start(
      @PathVariable UUID tripId,
      @Valid @RequestBody StartTripRequest request,
      CurrentActor actor) {

    return TripResponse.from(
        startTrip.execute(
            new StartTripCommand(
                tripId,
                request.vehicleId(),
                request.deviceStartedAt(),
                actor.userId(),
                actor.role())));
  }

  /**
   * Ends the run.
   *
   * <p>{@code /end}, not {@code /close}: this moves the trip to {@code COMPLETED}, meaning the crew
   * has finished driving. {@code CLOSED} additionally asserts that every child is accounted for,
   * and arrives with reconciliation.
   */
  @PostMapping("/{tripId}/end")
  @RequiresPermission("PERM-TRIP-END")
  public TripResponse end(@PathVariable UUID tripId, CurrentActor actor) {
    return TripResponse.from(completeTrip.execute(tripId, actor.userId(), actor.role()));
  }

  @PostMapping("/{tripId}/cancel")
  @RequiresPermission("PERM-TRIP-CANCEL")
  public TripResponse cancel(
      @PathVariable UUID tripId,
      @Valid @RequestBody CancelTripRequest request,
      CurrentActor actor) {
    return TripResponse.from(
        cancelTrip.execute(tripId, request.reason(), actor.userId(), actor.role()));
  }

  /**
   * Generates the trips a date should have, now, instead of waiting for the nightly job.
   *
   * <p>Needed whenever a timetable is corrected after generation has already run for the day — the
   * operator fixes the stop times and re-runs this, and the routes that were previously skipped
   * appear. Idempotent, so re-running it is always safe.
   *
   * <p>Guarded by {@code PERM-ROUTE-MANAGE} rather than a permission of its own. Generation
   * materialises the route timetable and nothing else, so the people entitled to run it are exactly
   * the people entitled to define that timetable; inventing a {@code PERM-TRIP-GENERATE} that the
   * permission matrix does not contain would be inventing a requirement (CLAUDE.md §21). If the
   * matrix later separates the two, this annotation is the only line that changes.
   */
  @PostMapping("/generate")
  @RequiresPermission("PERM-ROUTE-MANAGE")
  public TripGenerationResponse generate(
      @RequestParam(required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate serviceDate,
      CurrentActor actor) {

    LocalDate date = serviceDate == null ? LocalDate.now(clock) : serviceDate;
    return new TripGenerationResponse(date, materialiseTrips.execute(date, actor.userId()));
  }
}
