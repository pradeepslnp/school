package com.guardian.staff.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateTransportStaffRequest(
    @NotBlank String firstName,
    @NotBlank String lastName,
    @NotBlank String phone,
    // Optional, matching CreateTransportStaffRequest — no @NotBlank on either.
    String employeeCode,
    String vendorName) {}
