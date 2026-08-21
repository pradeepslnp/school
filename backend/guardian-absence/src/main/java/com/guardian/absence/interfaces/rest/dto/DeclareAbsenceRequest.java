package com.guardian.absence.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/**
 * {@code POST /students/{id}/absences} body.
 *
 * <p>Matches guardian-docs/04-api/TRIPS_BOARDING_API.md exactly:
 *
 * <pre>{@code
 * { "fromDate": "2026-08-05", "toDate": "2026-08-07", "direction": null, "reason": "Family travel" }
 * }</pre>
 *
 * <p>{@code direction} is nullable and null means both journeys. {@code reason} carries no
 * {@code @NotBlank} — it is optional by rule, not by oversight (BR-ABS-001).
 */
public record DeclareAbsenceRequest(
    @NotNull LocalDate fromDate,
    @NotNull LocalDate toDate,
    @Pattern(regexp = "PICKUP|DROP", message = "must be PICKUP, DROP, or omitted") String direction,
    // Bounded so a runaway client cannot write an unbounded blob into a safety record; long
    // enough that no real explanation is truncated.
    @Size(max = 500) String reason) {}
