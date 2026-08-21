package com.guardian.fleet.interfaces.rest.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record UpdateVehicleRequest(
    @NotBlank String displayName, @NotNull @Min(1) Integer seatingCapacity, String vendorName) {}
