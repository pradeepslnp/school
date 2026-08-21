package com.guardian.staff.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** Wire format for registering a driver or attendant (feature STF-001). */
public record CreateTransportStaffRequest(
    @NotNull UUID schoolId,
    @NotBlank String staffType,
    String employeeCode,
    @NotBlank String firstName,
    @NotBlank String lastName,
    @NotBlank String phone,
    String vendorName) {}
