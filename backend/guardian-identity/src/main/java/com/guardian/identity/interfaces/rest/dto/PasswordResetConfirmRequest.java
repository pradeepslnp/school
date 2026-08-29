package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for completing a password reset (ADR-0012, feature IAM-010): the email the code was
 * sent to, the 6-digit code, and the new password.
 *
 * <p>Bean validation catches an empty submission at the boundary; the code's validity and the
 * password's strength are decided server-side ({@code ResetPasswordUseCase}, {@code PasswordPolicy}),
 * never trusted from here. The email + code pair identifies the account — the code alone is not
 * unique — mirroring how phone sign-in verifies a code against a resolved phone.
 */
public record PasswordResetConfirmRequest(
    @NotBlank @Email @Size(max = 255) String email,
    @NotBlank String otp,
    @NotBlank @Size(max = 128) String password) {}
