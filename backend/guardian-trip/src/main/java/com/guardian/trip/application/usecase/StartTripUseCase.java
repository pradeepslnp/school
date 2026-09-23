package com.guardian.trip.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.fleet.application.result.VehicleEligibilityResult;
import com.guardian.fleet.application.usecase.GetVehicleEligibilityUseCase;
import com.guardian.fleet.domain.VehicleId;
import com.guardian.staff.application.result.StaffEligibilityResult;
import com.guardian.staff.application.usecase.GetStaffEligibilityUseCase;
import com.guardian.staff.domain.StaffId;
import com.guardian.trip.application.command.StartTripCommand;
import com.guardian.trip.application.port.CrewDirectory;
import com.guardian.trip.application.port.TripManifestRepository;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.Trip;
import com.guardian.trip.domain.TripStatus;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Begins a run — the single most consequential write in the platform.
 *
 * <p>Everything downstream hangs off this moment. The manifest materialised here is the fixed
 * expectation that trip-close reconciliation compares the boarding record against (BR-SAFE-001);
 * until it exists, MOD-09 has nothing to record events against and the parent app has nothing to
 * show. Getting the order of the checks right matters as much as the checks themselves, so it is
 * stated explicitly:
 *
 * <ol>
 *   <li><strong>The trip exists and may start</strong> (BR-TRIP-002). Checked first because every
 *       later check is wasted work otherwise, and because "already started" is the single most
 *       likely failure — two crew members tapping start within a second of each other.
 *   <li><strong>The caller is entitled to start <em>this</em> run</strong> (BR-TRIP-006). Holding
 *       {@code PERM-TRIP-START} says a driver may start trips; it does not say <em>which</em>.
 *       Scope is checked here because no endpoint annotation can express it — the same reasoning
 *       {@code DeclareAbsenceUseCase} applies to a guardian and their own child.
 *   <li><strong>The vehicle and the crew are fit to carry children</strong> (BR-TRIP-004, via
 *       BR-FLEET-002 and BR-STAFF-001/002). Both halves are asked of the modules that own them
 *       rather than re-implemented here — {@code GetVehicleEligibilityUseCase}'s own Javadoc names
 *       MOD-08 as the caller that combines them.
 *   <li><strong>Neither is already out on another run</strong> (BR-TRIP-005). A bus recorded as
 *       being in two places is a record nobody can act on in an emergency.
 *   <li><strong>The manifest is materialised, and is not empty</strong> (BR-TRIP-003 🔴). An empty
 *       manifest means a run that can record nothing — a timetable or assignment mistake, and far
 *       better refused at 06:30 than discovered at reconciliation.
 *   <li><strong>Only then does the trip move</strong>, guarded at the database by its expected
 *       status, so the race in step 1 closes properly rather than approximately.
 * </ol>
 *
 * <p>All of it in one transaction: a trip marked in progress whose manifest failed to write is a
 * bus carrying children the platform cannot name.
 */
@Service
public class StartTripUseCase {

  private static final String ROLE_TRANSPORT_MANAGER = "TRANSPORT_MANAGER";

  private final TripRepository trips;
  private final TripManifestRepository manifests;
  private final CrewDirectory crew;
  private final GetVehicleEligibilityUseCase vehicleEligibility;
  private final GetStaffEligibilityUseCase staffEligibility;
  private final AuditPort audit;
  private final Clock clock;

  public StartTripUseCase(
      TripRepository trips,
      TripManifestRepository manifests,
      CrewDirectory crew,
      GetVehicleEligibilityUseCase vehicleEligibility,
      GetStaffEligibilityUseCase staffEligibility,
      AuditPort audit,
      Clock clock) {
    this.trips = trips;
    this.manifests = manifests;
    this.crew = crew;
    this.vehicleEligibility = vehicleEligibility;
    this.staffEligibility = staffEligibility;
    this.audit = audit;
    this.clock = clock;
  }

  @Transactional
  @BusinessRule({
    "BR-TRIP-002",
    "BR-TRIP-003",
    "BR-TRIP-004",
    "BR-TRIP-005",
    "BR-TRIP-006",
    "BR-TRIP-008",
    // Materialising the manifest is where these two are actually enforced: absences are
    // subtracted (BR-ABS-002) and withdrawn students are excluded (BR-STU-004). Neither rule
    // has an enforcement point in the module that documents it — the moment they bite is here.
    "BR-ABS-002",
    "BR-STU-004"
  })
  public Trip execute(StartTripCommand command) {
    Trip trip =
        trips
            .findById(command.tripId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.TRIP_NOT_FOUND, "Trip", command.tripId()));

    requireTransitionAllowed(trip, TripStatus.IN_PROGRESS);

    Optional<UUID> staffId = crew.staffIdForUser(command.actorUserId());
    requireEntitledToStart(trip, staffId, command.actorRole());

    if (command.vehicleId() == null) {
      // Not an eligibility failure — nothing was named to check. A missing required field is a
      // 400, and the DTO's @NotNull catches it first for any caller that goes through the API.
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING,
          "BR-TRIP-004",
          Map.of("field", "vehicleId"));
    }
    requireVehicleEligible(command.vehicleId());
    staffId.ifPresent(this::requireCrewEligible);

    requireNotAlreadyOut(command, staffId);

    // BR-TRIP-003 🔴 — materialise before the status moves. Done the other way round, a failure
    // here would leave a trip in progress with no manifest, which reconciliation reads as "no
    // children were expected" rather than as the fault it is.
    manifests.materialiseFor(trip.id());
    if (manifests.countFor(trip.id()) == 0) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_MANIFEST_EMPTY,
          "BR-TRIP-003",
          Map.of(
              "tripId", trip.id().toString(),
              "reason",
              "No student is assigned to this route for this direction, or every assigned"
                  + " student is declared absent"));
    }

    Instant startedAt = clock.instant();
    boolean moved =
        trips.start(trip.id(), command.vehicleId(), startedAt, command.deviceStartedAt());
    if (!moved) {
      // Another caller started it between the read above and this update. The guarded UPDATE is
      // what makes that safe; this is how the loser is told.
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_INVALID_STATUS_TRANSITION,
          "BR-TRIP-002",
          Map.of("reason", "This trip was started by someone else a moment ago"));
    }

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(command.actorUserId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("TRIP_STARTED")
            .subject("Trip", trip.id())
            .before(Map.of("status", TripStatus.SCHEDULED.name()))
            .after(
                Map.of(
                    "status", TripStatus.IN_PROGRESS.name(),
                    "vehicleId", command.vehicleId().toString(),
                    "manifestSize", String.valueOf(manifests.countFor(trip.id())),
                    "startedAt", startedAt.toString()))
            .build());

    return trips
        .findById(trip.id())
        .orElseThrow(
            () -> new ResourceNotFoundException(ErrorCode.TRIP_NOT_FOUND, "Trip", trip.id()));
  }

  private void requireTransitionAllowed(Trip trip, TripStatus target) {
    if (!trip.status().canTransitionTo(target)) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_INVALID_STATUS_TRANSITION,
          "BR-TRIP-002",
          Map.of(
              "currentStatus", trip.status().name(),
              "requestedStatus", target.name(),
              "allowedNext", trip.status().allowedNext().toString()));
    }
  }

  /**
   * BR-TRIP-006 — the assigned crew, or a transport manager.
   *
   * <p>A transport manager is allowed deliberately: buses start without their rostered driver often
   * enough (illness, a substitution made at the gate) that refusing would push the workaround into
   * sharing a driver's login, which is worse for every record that follows.
   */
  private void requireEntitledToStart(Trip trip, Optional<UUID> staffId, String actorRole) {
    if (ROLE_TRANSPORT_MANAGER.equals(actorRole)) {
      return;
    }
    boolean rostered = staffId.map(id -> trips.isRosteredCrewFor(trip.id(), id)).orElse(false);
    if (!rostered) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_NOT_AUTHORISED_ACTOR,
          "BR-TRIP-006",
          Map.of("tripId", trip.id().toString()));
    }
  }

  /**
   * BR-TRIP-004, vehicle half — refused with the <em>specific</em> failing check.
   *
   * <p>ERROR_CATALOG.md states the reason plainly: "A generic 'cannot start trip' at 6:30 AM is
   * not actionable." A driver told the fitness certificate expired can phone the office and be
   * given another bus; a driver told "not eligible" can only stand there.
   */
  private void requireVehicleEligible(UUID vehicleId) {
    VehicleEligibilityResult result = vehicleEligibility.execute(VehicleId.of(vehicleId));
    if (result.eligible()) {
      return;
    }

    String failed =
        result.checks().stream()
            .filter(check -> !check.passed())
            .map(check -> check.check())
            .findFirst()
            .orElse("");

    ErrorCode code =
        switch (failed) {
          case "VEHICLE_ACTIVE" -> ErrorCode.VEHICLE_NOT_ACTIVE;
          case "MANDATORY_DOCUMENTS_VALID" -> ErrorCode.VEHICLE_DOCUMENT_EXPIRED;
          // A check MOD-05 adds later, before this switch learns about it. Falling back to the
          // documents code would name the wrong cause, so the generic vehicle code is used and
          // the detail still carries the check's own name.
          default -> ErrorCode.VEHICLE_NOT_ACTIVE;
        };

    throw new BusinessRuleViolationException(
        code,
        "BR-FLEET-002",
        Map.of("vehicleId", vehicleId.toString(), "failedCheck", failed));
  }

  /** BR-TRIP-004, crew half. Same reasoning as the vehicle half above. */
  private void requireCrewEligible(UUID staffId) {
    StaffEligibilityResult result = staffEligibility.execute(StaffId.of(staffId));
    if (result.eligible()) {
      return;
    }

    String failed =
        result.checks().stream()
            .filter(check -> !check.passed())
            .map(check -> check.check())
            .findFirst()
            .orElse("");

    ErrorCode code =
        switch (failed) {
          case "STAFF_VERIFIED" -> ErrorCode.STAFF_NOT_VERIFIED;
          case "MANDATORY_CREDENTIALS_VALID" -> ErrorCode.STAFF_LICENCE_EXPIRED;
          default -> ErrorCode.STAFF_NOT_VERIFIED;
        };

    throw new BusinessRuleViolationException(
        code, "BR-STAFF-001", Map.of("staffId", staffId.toString(), "failedCheck", failed));
  }

  private void requireNotAlreadyOut(StartTripCommand command, Optional<UUID> staffId) {
    if (trips.vehicleIsOnAnotherTrip(command.vehicleId(), command.tripId())) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_VEHICLE_ON_ANOTHER_TRIP,
          "BR-TRIP-005",
          Map.of("vehicleId", command.vehicleId().toString()));
    }
    staffId.ifPresent(
        id -> {
          if (trips.staffIsOnAnotherTrip(id, command.tripId())) {
            throw new BusinessRuleViolationException(
                ErrorCode.STAFF_ALREADY_ON_ACTIVE_TRIP,
                "BR-STAFF-004",
                Map.of("staffId", id.toString()));
          }
        });
  }
}
