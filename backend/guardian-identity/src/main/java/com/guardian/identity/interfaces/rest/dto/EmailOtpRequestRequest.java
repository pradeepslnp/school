package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for asking for an emailed sign-in code (IAM-001, ADR-0012).
 *
 * <p>The endpoint answers identically whether or not the address has an account, so nothing here
 * reveals a result — see {@code RequestEmailOtpUseCase}.
 */
public record EmailOtpRequestRequest(@NotBlank @Email @Size(max = 255) String email) {}
