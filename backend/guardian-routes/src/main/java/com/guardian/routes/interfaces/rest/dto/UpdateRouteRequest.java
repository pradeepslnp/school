package com.guardian.routes.interfaces.rest.dto;

import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * A {@code PATCH} body: every field optional, null meaning leave unchanged.
 *
 * @param operatingDays comma-separated three-letter day codes, e.g. {@code "MON,TUE,WED,THU,FRI"}.
 *     A string rather than a list because that is exactly what the column holds, and translating
 *     between two shapes at the boundary is one more place for them to disagree. An unrecognised
 *     code is refused rather than skipped — a silently dropped {@code TEU} produces a route that
 *     stops running on Tuesdays and tells nobody.
 */
public record UpdateRouteRequest(
    @Size(max = 255) String name,
    UUID defaultVehicleId,
    @Size(max = 27) String operatingDays) {}
