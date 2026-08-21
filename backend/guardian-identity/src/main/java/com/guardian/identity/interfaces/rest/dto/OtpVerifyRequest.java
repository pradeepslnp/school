package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for {@code POST /auth/otp/verify}.
 *
 * <p>{@code otp} carries no {@code @Pattern} on purpose. A bean-validation failure returns {@code
 * 400 VALIDATION_FAILED} with the offending field named, which tells anything probing the endpoint
 * exactly what shape a code has; a wrong-shaped code is instead refused as {@code
 * AUTH_CREDENTIALS_INVALID} alongside every other wrong code, in {@code VerifyOtpUseCase}.
 *
 * <p>{@code clientType} is required and never defaulted — it decides the refresh lifetime, so a
 * default would silently decide how long a stolen token stays usable.
 */
public record OtpVerifyRequest(
    @NotBlank @Size(max = 32) String phone,
    @NotBlank @Size(max = 16) String otp,
    @NotBlank @Size(max = 24) String clientType,
    @Size(max = 255) String deviceIdentifier) {}
