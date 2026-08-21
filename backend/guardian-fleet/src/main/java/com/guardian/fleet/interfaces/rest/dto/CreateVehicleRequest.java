package com.guardian.fleet.interfaces.rest.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * Wire format for registering a vehicle (feature FLT-001).
 *
 * <p>{@code displayName} is what parents see in notifications — "Bus 12", not a plate number
 * (NTF-BOARD-01, guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md).
 */
public record CreateVehicleRequest(
    @NotNull UUID schoolId,
    @NotBlank String registrationNo,
    @NotBlank String displayName,
    @NotBlank String vehicleType,
    @NotNull @Min(1) Integer seatingCapacity,
    String vendorName) {}
