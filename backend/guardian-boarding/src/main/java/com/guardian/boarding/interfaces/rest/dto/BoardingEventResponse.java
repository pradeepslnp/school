package com.guardian.boarding.interfaces.rest.dto;

import com.guardian.boarding.domain.BoardingEvent;
import java.time.Instant;
import java.util.UUID;

/** Wire form of a recorded boarding event. */
public record BoardingEventResponse(
    UUID id,
    UUID tripId,
    UUID studentId,
    UUID stopId,
    String eventType,
    String verificationMethod,
    UUID clientEventId,
    boolean isOverride,
    Instant occurredAt,
    Instant recordedAt) {

  public static BoardingEventResponse from(BoardingEvent event) {
    return new BoardingEventResponse(
        event.id(),
        event.tripId(),
        event.studentId(),
        event.stopId(),
        event.eventType().name(),
        event.verificationMethod().name(),
        event.clientEventId(),
        event.isOverride(),
        event.occurredAt(),
        event.recordedAt());
  }
}
