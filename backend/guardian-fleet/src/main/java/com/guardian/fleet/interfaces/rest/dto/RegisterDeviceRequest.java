package com.guardian.fleet.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record RegisterDeviceRequest(
    @NotBlank String deviceIdentifier,
    @NotBlank String vendorCode,
    @NotBlank String credentialSecret) {}
