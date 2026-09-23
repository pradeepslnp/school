package com.guardian.boarding.interfaces.rest.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * A boarding or alighting, as the driver app sends it
 * (documentation/04-api/TRIPS_BOARDING_API.md).
 *
 * @param clientEventId <strong>mandatory.</strong> Generated on the handset before the attempt, it
 *     is both the idempotency key and the database's uniqueness guarantee (BR-BOARD-009). An
 *     offline queue syncs by retrying (ADR-0008); without it a child is recorded boarding twice.
 * @param occurredAt the handset's clock when the crew tapped. The server stamps its own {@code
 *     recordedAt} regardless — the device clock is never authoritative (BR-BOARD-008).
 * @param stopId null when the event happens at the school rather than at a route stop.
 */
public record RecordBoardingRequest(
    @NotNull UUID clientEventId,
    @NotNull UUID studentId,
    UUID stopId,
    @NotNull String eventType,
    String verificationMethod,
    Instant occurredAt,
    Integer clockSkewSeconds,
    @DecimalMin("-90") @DecimalMax("90") BigDecimal latitude,
    @DecimalMin("-180") @DecimalMax("180") BigDecimal longitude,
    boolean isOverride,
    @Size(max = 500) String overrideReason) {}
