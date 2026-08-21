package com.guardian.routes.application.command;

import java.time.LocalTime;

/** One stop as submitted to {@code ReplaceStopsUseCase} — not yet validated into a {@code Stop}. */
public record StopInput(
    int sequenceNo,
    String name,
    double latitude,
    double longitude,
    int geofenceRadiusM,
    LocalTime scheduledPickupTime,
    LocalTime scheduledDropTime,
    String landmark) {}
