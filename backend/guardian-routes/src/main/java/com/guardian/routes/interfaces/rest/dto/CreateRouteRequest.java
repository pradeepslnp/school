package com.guardian.routes.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Wire format for creating a route (feature RTE-001).
 *
 * @param operatingDays comma-separated three-letter day codes, e.g. {@code "MON,TUE,WED,THU,FRI"}.
 *     Optional — omitting it means the five-day school week, so the ordinary case needs no answer.
 */
public record CreateRouteRequest(
    @NotNull UUID schoolId,
    @NotBlank String code,
    @NotBlank String name,
    UUID defaultVehicleId,
    @Size(max = 27) String operatingDays) {}
