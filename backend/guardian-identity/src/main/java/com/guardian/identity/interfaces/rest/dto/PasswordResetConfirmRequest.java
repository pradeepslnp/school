package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for completing a password reset (ADR-0012, feature IAM-010): the token from the
 * emailed link plus the new password.
 *
 * <p>Same division of responsibility as {@link AcceptInvitationRequest}: bean validation catches an
 * empty submission, the use case and {@code PasswordPolicy} decide everything that matters.
 */
public record PasswordResetConfirmRequest(
    @NotBlank String token, @NotBlank @Size(max = 128) String password) {}
