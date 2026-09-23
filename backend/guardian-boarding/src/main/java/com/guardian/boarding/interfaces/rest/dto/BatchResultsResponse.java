package com.guardian.boarding.interfaces.rest.dto;

import java.util.List;

/**
 * The batch envelope: {@code { "data": { "results": [...] } }}.
 *
 * <p>A wrapper object rather than a bare array, because that is the shape the driver app reads
 * ({@code response.data['results']}) and the shape the API document specifies. It also leaves room
 * for batch-level fields later without moving the results.
 */
public record BatchResultsResponse(List<BatchEventOutcomeResponse> results) {}
