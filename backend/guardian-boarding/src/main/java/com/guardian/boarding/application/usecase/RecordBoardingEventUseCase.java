package com.guardian.boarding.application.usecase;

import com.guardian.boarding.application.command.RecordBoardingCommand;
import com.guardian.boarding.application.port.BoardingEventRepository;
import com.guardian.boarding.application.port.TripManifestReadModel;
import com.guardian.boarding.domain.BoardingEvent;
import com.guardian.boarding.domain.BoardingEventType;
import com.guardian.boarding.domain.ManifestEntryStatus;
import com.guardian.boarding.domain.VerificationMethod;
import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import java.time.Clock;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Records that a child boarded or alighted — the write the whole product turns on (BRD-001..004).
 *
 * <p>Until this existed, every safety record the platform describes was a read over tables nothing
 * wrote. The order of what happens here is the design, so it is stated plainly:
 *
 * <ol>
 *   <li><strong>Idempotency first, before any rule</strong> (BR-BOARD-009). A queued offline event
 *       retried an hour later must return the original record, not be refused by a rule its first
 *       attempt already passed — "already boarded" for an event that <em>is</em> the boarding is
 *       the classic offline-sync bug, and checking the key first is what avoids it.
 *   <li><strong>The trip must be accepting events.</strong> Recording against a run that has not
 *       started has no manifest to record against; against one already ended, it is a correction,
 *       which carries a reason and an actor.
 *   <li><strong>Wrong-vehicle detection before manifest refusal</strong> (BR-SAFE-003 🔴). Both
 *       conditions are "not on this manifest", and the order decides which the crew is told. A
 *       child who belongs on another bus that is running right now is a safety event, not a data
 *       entry error, and saying so is the difference between someone going to look for them and
 *       someone tapping override.
 *   <li><strong>Then the ordinary rules</strong> — on the manifest (BR-BOARD-003), not boarding
 *       twice (BR-BOARD-005), not alighting without boarding (BR-BOARD-006), not alighting at the
 *       wrong stop (BR-BOARD-004) — each overridable by an authorised actor with a reason, none
 *       overridable silently.
 *   <li><strong>Append, project, audit — one transaction.</strong> An event written without its
 *       manifest status moved is a child the crew's screen still shows as waiting at a stop the
 *       bus has left.
 * </ol>
 *
 * <p><strong>What this deliberately does not do:</strong> notify anybody. BR-BOARD-004's wrong-stop
 * override and BR-SAFE-003's wrong-vehicle alert both require guardians to be told immediately, and
 * MOD-12's dispatch side does not exist — nothing in the platform writes a notification row. The
 * events are recorded and audited correctly and the parent app shows them on its next read, but no
 * push goes out. That gap is tracked in IMPLEMENTATION_STATUS.md rather than hidden behind a call
 * to a sender that is not there.
 */
@Service
public class RecordBoardingEventUseCase {

  private final BoardingEventRepository events;
  private final TripManifestReadModel trips;
  private final AuditPort audit;
  private final Clock clock;

  public RecordBoardingEventUseCase(
      BoardingEventRepository events,
      TripManifestReadModel trips,
      AuditPort audit,
      Clock clock) {
    this.events = events;
    this.trips = trips;
    this.audit = audit;
    this.clock = clock;
  }

  @Transactional
  @BusinessRule({
    "BR-BOARD-001",
    "BR-BOARD-002",
    "BR-BOARD-003",
    "BR-BOARD-004",
    "BR-BOARD-005",
    "BR-BOARD-006",
    "BR-BOARD-009",
    "BR-SAFE-003"
  })
  public BoardingEvent execute(RecordBoardingCommand command) {
    Optional<BoardingEvent> alreadyRecorded =
        events.findByClientEventId(command.clientEventId());
    if (alreadyRecorded.isPresent()) {
      return alreadyRecorded.get();
    }

    requireTripAcceptsEvents(command.tripId());

    boolean onManifest = events.isOnManifest(command.tripId(), command.studentId());
    if (!onManifest) {
      requireNotOnAnotherRunningTrip(command);
      requireOverride(
          command, ErrorCode.BOARDING_STUDENT_NOT_ON_MANIFEST, "BR-BOARD-003", Map.of());
    }

    Optional<BoardingEventType> last =
        events.lastEventTypeFor(command.tripId(), command.studentId());

    if (command.eventType() == BoardingEventType.BOARD) {
      if (last.orElse(null) == BoardingEventType.BOARD) {
        // Not overridable: a second board with no alight between is either a double tap or a
        // record of something that cannot have happened. Neither is fixed by a reason.
        throw new BusinessRuleViolationException(
            ErrorCode.BOARDING_ALREADY_BOARDED,
            "BR-BOARD-005",
            Map.of("studentId", command.studentId().toString()));
      }
    } else {
      if (last.orElse(null) != BoardingEventType.BOARD) {
        requireOverride(command, ErrorCode.BOARDING_NOT_BOARDED, "BR-BOARD-006", Map.of());
      }
      requireCorrectStopOrOverride(command);
    }

    BoardingEvent appended =
        events.append(
            new BoardingEvent(
                null,
                command.tripId(),
                command.studentId(),
                command.stopId(),
                command.eventType(),
                command.verificationMethod() == null
                    ? VerificationMethod.MANUAL
                    : command.verificationMethod(),
                command.actorUserId(),
                command.actorRole(),
                command.clientEventId(),
                null,
                command.isOverride(),
                blankToNull(command.overrideReason()),
                command.occurredAt() == null ? clock.instant() : command.occurredAt(),
                clock.instant(),
                command.clockSkewSeconds(),
                command.deviceLatitude(),
                command.deviceLongitude()));

    events.updateManifestStatus(
        command.tripId(),
        command.studentId(),
        command.eventType() == BoardingEventType.BOARD
            ? ManifestEntryStatus.BOARDED
            : ManifestEntryStatus.ALIGHTED);

    // In the same transaction as the write (BR-AUD-002 🔴). A boarding record whose audit entry
    // failed is a safety record nobody can attribute.
    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(command.actorUserId(), AuditRecord.ActorType.USER, command.actorRole())
            .action(
                command.eventType() == BoardingEventType.BOARD
                    ? "STUDENT_BOARDED"
                    : "STUDENT_ALIGHTED")
            .subject("BoardingEvent", appended.id())
            .reason(blankToNull(command.overrideReason()))
            .after(
                Map.of(
                    "tripId", command.tripId().toString(),
                    "studentId", command.studentId().toString(),
                    "eventType", command.eventType().name(),
                    "isOverride", String.valueOf(command.isOverride())))
            .build());

    return appended;
  }

  private void requireTripAcceptsEvents(UUID tripId) {
    String status =
        trips
            .statusOf(tripId)
            .orElseThrow(
                () -> new ResourceNotFoundException(ErrorCode.TRIP_NOT_FOUND, "Trip", tripId));

    if (!"IN_PROGRESS".equals(status)) {
      throw new BusinessRuleViolationException(
          ErrorCode.TRIP_NOT_STARTED,
          "BR-BOARD-002",
          Map.of("tripStatus", status));
    }
  }

  /**
   * BR-SAFE-003 🔴 — the child belongs on another bus that is running right now.
   *
   * <p>Never overridable. Every other refusal here can be waved through by an authorised actor
   * with a reason, because every other one has a legitimate real-world version. This one does not:
   * if the child is expected on another active run, putting them on this bus is the mistake the
   * whole platform exists to catch, and a reason field would turn the catch into a formality.
   */
  private void requireNotOnAnotherRunningTrip(RecordBoardingCommand command) {
    Optional<UUID> otherTrip =
        events.otherTripExpectingStudent(command.tripId(), command.studentId());
    if (otherTrip.isPresent()) {
      throw new BusinessRuleViolationException(
          ErrorCode.BOARDING_WRONG_VEHICLE,
          "BR-SAFE-003",
          Map.of(
              "studentId", command.studentId().toString(),
              "expectedTripId", otherTrip.get().toString()));
    }
  }

  /** BR-BOARD-004 🔴 — alighting somewhere other than the child's own stop. */
  private void requireCorrectStopOrOverride(RecordBoardingCommand command) {
    if (command.stopId() == null) {
      // Alighting at the school rather than at a route stop: the expected case on a pickup run.
      return;
    }
    Optional<UUID> expected = events.expectedStopFor(command.tripId(), command.studentId());
    if (expected.isPresent() && !expected.get().equals(command.stopId())) {
      requireOverride(
          command,
          ErrorCode.BOARDING_WRONG_STOP,
          "BR-BOARD-004",
          Map.of("expectedStopId", expected.get().toString()));
    }
  }

  /**
   * Lets an authorised actor proceed, with a reason, or refuses with the specific code.
   *
   * <p>The reason is what makes an override a decision rather than a bypass: it is stored on the
   * row, surfaced in the override register (A-55), and a database constraint rejects an empty one
   * (BR-AUD-004), so no future code path can write one without.
   */
  private void requireOverride(
      RecordBoardingCommand command,
      ErrorCode code,
      String businessRule,
      Map<String, Object> context) {

    if (command.isOverride() && !blank(command.overrideReason())) {
      return;
    }
    if (command.isOverride()) {
      throw new BusinessRuleViolationException(
          ErrorCode.BOARDING_OVERRIDE_REASON_REQUIRED, "BR-AUD-004", context);
    }
    throw new BusinessRuleViolationException(code, businessRule, context);
  }

  private static boolean blank(String value) {
    return value == null || value.isBlank();
  }

  private static String blankToNull(String value) {
    return blank(value) ? null : value.trim();
  }
}
