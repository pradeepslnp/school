package com.guardian.routes.application.command;

import com.guardian.routes.domain.StopId;
import java.time.LocalTime;

/** One stop as submitted to {@code ReplaceStopsUseCase} — not yet validated into a {@code Stop}. */
/**
 * One stop in a {@code PUT /routes/{id}/stops} list.
 *
 * @param id the stop being kept, or null for a new stop. Keeping the id is what keeps every student
 *     assigned to that stop assigned to it through an edit.
 */
public record StopInput(
    StopId id,
    int sequenceNo,
    String name,
    double latitude,
    double longitude,
    int geofenceRadiusM,
    LocalTime scheduledPickupTime,
    LocalTime scheduledDropTime,
    String landmark) {}
