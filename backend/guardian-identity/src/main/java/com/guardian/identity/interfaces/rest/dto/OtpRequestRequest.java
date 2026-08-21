package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for {@code POST /auth/otp/request}.
 *
 * <p>The only validation is presence and a length ceiling. Format is checked against the region
 * profile server-side (ADR-0007), not by a pattern here that would reject valid numbers in the next
 * country the platform sells into — and a {@code 400} for a malformed number would answer
 * differently from a {@code 202} for an unregistered one, which is the enumeration this endpoint
 * exists to prevent.
 */
public record OtpRequestRequest(@NotBlank @Size(max = 32) String phone) {}
