package com.guardian.trip.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.Trip;
import com.guardian.trip.domain.TripStatus;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Calls off a run (BR-TRIP-007).
 *
 * <p>The reason is mandatory and is not a formality: it is the text every affected guardian is
 * told. A cancelled run with no reason produces a notification that says a bus is not coming and
 * cannot say why, which is the moment a parent starts phoning the school.
 *
 * <p>Reachable from {@code SCHEDULED} and from {@code IN_PROGRESS} — a breakdown mid-route is a
 * cancellation, and refusing it would leave the trip showing as running while the children are
 * being moved to another bus.
 *
 * <p><strong>The guardian notification this rule requires is not sent yet.</strong> MOD-12's
 * dispatch side is unbuilt: nothing in the platform writes a notification row. The cancellation is
 * recorded and audited correctly, and the parent app will show the run as cancelled on its next
 * read — but no push or SMS goes out. That gap is tracked in IMPLEMENTATION_STATUS.md rather than
 * papered over with a silent no-op call to a sender that does not exist.
 */
@Service
public class CancelTripUseCase {

  private final TripRepository trips;
  private final AuditPort audit;
  private final Clock clock;

  public CancelTripUseCase(TripRepository trips, AuditPort audit, Clock clock) {
    this.trips = trips;
    this.audit = audit;
    this.clock = clock;
  }

  @Transactional
  @BusinessRule({"BR-TRIP-002", "BR-TRIP-007"})
  public Trip execute(UUID tripId, String reason, UUID actorUserId, String actorRole) {
    String trimmed = reason == null ? "" : reason.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_CANCELLATION_REASON_REQUIRED,
          "BR-TRIP-007",
          Map.of("reason", "Affected guardians are told why the bus is not coming"));
    }

    Trip trip =
        trips
            .findById(tripId)
            .orElseThrow(
                () -> new ResourceNotFoundException(ErrorCode.TRIP_NOT_FOUND, "Trip", tripId));

    if (!trip.status().canTransitionTo(TripStatus.CANCELLED)) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_INVALID_STATUS_TRANSITION,
          "BR-TRIP-002",
          Map.of(
              "currentStatus", trip.status().name(),
              "requestedStatus", TripStatus.CANCELLED.name(),
              "allowedNext", trip.status().allowedNext().toString()));
    }

    Instant at = clock.instant();
    boolean moved = trips.transition(tripId, trip.status(), TripStatus.CANCELLED, at, trimmed);
    if (!moved) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_INVALID_STATUS_TRANSITION,
          "BR-TRIP-002",
          Map.of("reason", "This trip changed status a moment ago"));
    }

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("TRIP_CANCELLED")
            .subject("Trip", tripId)
            .reason(trimmed)
            .before(Map.of("status", trip.status().name()))
            .after(Map.of("status", TripStatus.CANCELLED.name()))
            .build());

    return trips
        .findById(tripId)
        .orElseThrow(
            () -> new ResourceNotFoundException(ErrorCode.TRIP_NOT_FOUND, "Trip", tripId));
  }
}
