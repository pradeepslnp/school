package com.guardian.boarding.domain;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * An append-only record that a child boarded or alighted (MOD-09, BR-BOARD-001 🔴).
 *
 * <p>The most safety-critical record the platform holds. Three properties are load-bearing:
 *
 * <ul>
 *   <li><strong>It is never updated or deleted.</strong> A mistake is corrected by a new,
 *       compensating record pointing back at this one ({@code correctsEventId}) — so the history
 *       still shows what was believed at the time, which is what an investigation needs
 *       (BR-BOARD-001).
 *   <li><strong>Two clocks.</strong> {@code occurredAt} is the driver's handset; {@code recordedAt}
 *       is the server. On an offline-first client those differ by hours (ADR-0008), and both
 *       matter: reports order by what the crew saw, investigations read both (BR-BOARD-008).
 *   <li><strong>The role is captured as held at the time</strong> (BR-AUD-003). Roles change, and a
 *       record showing today's role for last term's action is misleading evidence.
 * </ul>
 *
 * @param clientEventId the idempotency key, generated on the handset. Both the retry key and the
 *     database's uniqueness guarantee (BR-BOARD-009): an offline queue syncs by retrying, and
 *     without this a child would be recorded boarding twice.
 * @param stopId null when the event happens at the school rather than at a route stop.
 * @param deviceLatitude null when the handset had no fix. A boarding event without a position is
 *     worth far more than no boarding event (V23).
 */
public record BoardingEvent(
    UUID id,
    UUID tripId,
    UUID studentId,
    UUID stopId,
    BoardingEventType eventType,
    VerificationMethod verificationMethod,
    UUID actorId,
    String actorRole,
    UUID clientEventId,
    UUID correctsEventId,
    boolean isOverride,
    String overrideReason,
    Instant occurredAt,
    Instant recordedAt,
    Integer clockSkewSeconds,
    BigDecimal deviceLatitude,
    BigDecimal deviceLongitude) {

  public BoardingEvent {
    Objects.requireNonNull(tripId, "tripId");
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(eventType, "eventType");
    Objects.requireNonNull(verificationMethod, "verificationMethod");
    Objects.requireNonNull(actorId, "actorId");
    Objects.requireNonNull(actorRole, "actorRole");
    Objects.requireNonNull(clientEventId, "clientEventId");
    Objects.requireNonNull(occurredAt, "occurredAt");

    // Mirrors ck_boarding_override_reason. The database is the guarantee (BR-AUD-004); this is
    // here so the refusal names the field rather than surfacing a constraint violation.
    if (isOverride && (overrideReason == null || overrideReason.isBlank())) {
      throw new IllegalArgumentException("an override must carry a reason");
    }
    // Half a coordinate is not a position — a row that looks located and is not is worse than an
    // honestly empty one (ck_boarding_position_complete).
    if ((deviceLatitude == null) != (deviceLongitude == null)) {
      throw new IllegalArgumentException("latitude and longitude must be given together");
    }
  }
}
