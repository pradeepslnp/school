package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for {@code POST /auth/login}, matching guardian-docs/04-api/AUTHENTICATION_API.md.
 *
 * <p>{@code @Email} is safe to declare here, unlike the deliberate absence of a shape check on
 * {@code OtpVerifyRequest.otp}: an email address's format says nothing about whether an account
 * exists, so rejecting an obviously malformed one with {@code VALIDATION_FAILED} leaks nothing an
 * attacker did not already know. {@code password} carries no format constraint at all — a wrong
 * password is refused as {@code AUTH_CREDENTIALS_INVALID} by {@code StaffLoginUseCase}, alongside
 * an unknown email, so this DTO does not get to decide what "looks like" a valid one.
 *
 * <p>{@code clientType} is required and never defaulted — see {@link
 * com.guardian.identity.application.command.StaffLoginCommand}.
 */
public record StaffLoginRequest(
    @NotBlank @Email @Size(max = 255) String email,
    @NotBlank @Size(max = 255) String password,
    @NotBlank @Size(max = 24) String clientType) {}
