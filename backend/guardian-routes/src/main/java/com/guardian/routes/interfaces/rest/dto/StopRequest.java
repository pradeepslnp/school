package com.guardian.routes.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalTime;

/** Wire format for one stop within a {@code PUT /routes/{id}/stops} request (feature RTE-001). */
public record StopRequest(
    @NotNull Integer sequenceNo,
    @NotBlank String name,
    @NotNull Double latitude,
    @NotNull Double longitude,
    @NotNull Integer geofenceRadiusM,
    LocalTime scheduledPickupTime,
    LocalTime scheduledDropTime,
    String landmark) {}
