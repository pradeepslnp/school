package com.guardian.trip.interfaces.rest.dto;

import java.time.LocalDate;

/**
 * What a manual generation run did.
 *
 * <p>{@code created} is usually zero on a second run for the same date, and that is success, not a
 * failure — generation is idempotent (BR-TRIP-011). The response says which date was generated so
 * an operator who mistyped it can see that immediately.
 */
public record TripGenerationResponse(LocalDate serviceDate, int created) {}
