package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for requesting a password reset (ADR-0012, feature IAM-010): just the email address.
 *
 * <p>The endpoint answers identically whether or not an account exists, so nothing here reveals a
 * result — see {@code RequestPasswordResetUseCase}.
 */
public record PasswordResetRequest(@NotBlank @Email @Size(max = 255) String email) {}
