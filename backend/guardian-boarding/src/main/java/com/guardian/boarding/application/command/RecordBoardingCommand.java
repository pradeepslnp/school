package com.guardian.boarding.application.command;

import com.guardian.boarding.domain.BoardingEventType;
import com.guardian.boarding.domain.VerificationMethod;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * The crew recording that a child boarded or alighted (BRD-001 to BRD-004).
 *
 * @param clientEventId generated on the handset before the attempt, not by the server, so a retry
 *     after a timeout carries the same key and is recognised as the same event (BR-BOARD-009).
 * @param occurredAt the handset's clock when the crew tapped. Never used in place of server time.
 */
public record RecordBoardingCommand(
    UUID tripId,
    UUID studentId,
    UUID stopId,
    BoardingEventType eventType,
    VerificationMethod verificationMethod,
    UUID clientEventId,
    Instant occurredAt,
    Integer clockSkewSeconds,
    BigDecimal deviceLatitude,
    BigDecimal deviceLongitude,
    boolean isOverride,
    String overrideReason,
    UUID actorUserId,
    String actorRole) {

  public RecordBoardingCommand {
    Objects.requireNonNull(tripId, "tripId");
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(eventType, "eventType");
    Objects.requireNonNull(clientEventId, "clientEventId");
    Objects.requireNonNull(actorUserId, "actorUserId");
    Objects.requireNonNull(actorRole, "actorRole");
  }
}
