package com.guardian.boarding.application.usecase;

import com.guardian.boarding.application.command.RecordBoardingCommand;
import com.guardian.boarding.application.port.BoardingEventRepository;
import com.guardian.boarding.domain.BoardingEvent;
import com.guardian.boarding.domain.BoardingEventType;
import com.guardian.boarding.domain.ManifestEntryStatus;
import com.guardian.boarding.domain.VerificationMethod;
import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import java.time.Clock;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Writes an offline event that contradicts server state, flagged for a person (BR-SAFE-005 🔴).
 *
 * <p><strong>A separate bean on purpose.</strong> This is called from {@code
 * RecordBoardingBatchUseCase} immediately after a refusal, and it must run in its own transaction —
 * the refusal rolled back the one the single-event use case had opened. Spring applies
 * {@code @Transactional} through a proxy, and a proxy is bypassed by self-invocation: had this
 * stayed a private method on the batch use case, the annotation would have done nothing and the
 * write would have been lost silently. Losing exactly this write is the outcome BR-SAFE-005 exists
 * to prevent, so the boundary is made explicit rather than trusted to a method call.
 */
@Service
public class FlaggedBoardingWriter {

  private final BoardingEventRepository events;
  private final AuditPort audit;
  private final Clock clock;

  public FlaggedBoardingWriter(BoardingEventRepository events, AuditPort audit, Clock clock) {
    this.events = events;
    this.audit = audit;
    this.clock = clock;
  }

  @Transactional
  @BusinessRule("BR-SAFE-005")
  public BoardingEvent write(RecordBoardingCommand command, String conflict) {
    BoardingEvent flagged =
        events.appendFlagged(
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

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(command.actorUserId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("BOARDING_EVENT_FLAGGED_FOR_REVIEW")
            .subject("BoardingEvent", flagged.id())
            .reason(conflict)
            .after(
                Map.of(
                    "tripId", command.tripId().toString(),
                    "studentId", command.studentId().toString(),
                    "eventType", command.eventType().name(),
                    "conflict", conflict))
            .build());

    return flagged;
  }

  private static String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }
}
