package com.guardian.trip.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.trip.application.port.CrewDirectory;
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
 * Ends a run: the crew has finished driving (BR-TRIP-002).
 *
 * <p>{@code COMPLETED}, not {@code CLOSED}. The distinction is the point of having both: completing
 * says the bus has stopped and no further boarding will be recorded; closing says every child on
 * the manifest has been accounted for. Only the first is a crew action. The second requires
 * trip-close reconciliation (BR-TRIP-009 → BR-SAFE-001 🔴), which belongs to MOD-09 and is not
 * built — so this module deliberately ships no "close" endpoint rather than one that moves the
 * status without doing the reconciliation it claims (CLAUDE.md §6, no placeholder code).
 *
 * <p>Completing does not check that every child alighted. It cannot: that <em>is</em>
 * reconciliation, and a driver who cannot end their shift because a record is missing will end it
 * by closing the app, which loses the queued events instead (ADR-0008). The gap is surfaced
 * afterwards, to a transport manager, not enforced at the kerb.
 */
@Service
public class CompleteTripUseCase {

  private static final String ROLE_TRANSPORT_MANAGER = "TRANSPORT_MANAGER";

  private final TripRepository trips;
  private final CrewDirectory crew;
  private final AuditPort audit;
  private final Clock clock;

  public CompleteTripUseCase(
      TripRepository trips, CrewDirectory crew, AuditPort audit, Clock clock) {
    this.trips = trips;
    this.crew = crew;
    this.audit = audit;
    this.clock = clock;
  }

  @Transactional
  @BusinessRule({"BR-TRIP-002", "BR-TRIP-006", "BR-TRIP-008"})
  public Trip execute(UUID tripId, UUID actorUserId, String actorRole) {
    Trip trip =
        trips
            .findById(tripId)
            .orElseThrow(
                () -> new ResourceNotFoundException(ErrorCode.TRIP_NOT_FOUND, "Trip", tripId));

    if (!trip.status().canTransitionTo(TripStatus.COMPLETED)) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_INVALID_TRANSITION,
          "BR-TRIP-002",
          Map.of(
              "currentStatus", trip.status().name(),
              "requestedStatus", TripStatus.COMPLETED.name(),
              "allowedNext", trip.status().allowedNext().toString()));
    }

    requireEntitled(trip, actorUserId, actorRole);

    Instant endedAt = clock.instant();
    boolean moved =
        trips.transition(tripId, TripStatus.IN_PROGRESS, TripStatus.COMPLETED, endedAt, null);
    if (!moved) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_INVALID_TRANSITION,
          "BR-TRIP-002",
          Map.of("reason", "This trip was ended by someone else a moment ago"));
    }

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("TRIP_COMPLETED")
            .subject("Trip", tripId)
            .before(Map.of("status", TripStatus.IN_PROGRESS.name()))
            .after(Map.of("status", TripStatus.COMPLETED.name(), "endedAt", endedAt.toString()))
            .build());

    return trips
        .findById(tripId)
        .orElseThrow(
            () -> new ResourceNotFoundException(ErrorCode.TRIP_NOT_FOUND, "Trip", tripId));
  }

  private void requireEntitled(Trip trip, UUID actorUserId, String actorRole) {
    if (ROLE_TRANSPORT_MANAGER.equals(actorRole)) {
      return;
    }
    Optional<UUID> staffId = crew.staffIdForUser(actorUserId);
    boolean rostered = staffId.map(id -> trips.isRosteredCrewFor(trip.id(), id)).orElse(false);
    if (!rostered) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_NOT_ASSIGNED_CREW,
          "BR-TRIP-006",
          Map.of("tripId", trip.id().toString()));
    }
  }
}
