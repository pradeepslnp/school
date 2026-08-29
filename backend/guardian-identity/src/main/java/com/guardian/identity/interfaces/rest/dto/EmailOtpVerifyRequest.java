package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for exchanging an emailed sign-in code for a session (IAM-001, ADR-0012).
 *
 * <p>The email + code pair identifies the account: a 6-digit code is not unique on its own, exactly
 * as in the phone flow where it is paired with the number.
 *
 * @param clientType required and never defaulted — see {@code VerifyEmailOtpCommand}.
 */
public record EmailOtpVerifyRequest(
    @NotBlank @Email @Size(max = 255) String email,
    @NotBlank String otp,
    @NotBlank String clientType,
    @Size(max = 128) String deviceIdentifier) {}
