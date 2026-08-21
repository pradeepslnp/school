package com.guardian.routes.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** Wire format for creating a route (feature RTE-001). */
public record CreateRouteRequest(
    @NotNull UUID schoolId, @NotBlank String code, @NotBlank String name, UUID defaultVehicleId) {}
