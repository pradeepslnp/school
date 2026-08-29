package com.guardian.identity.application.command;

/**
 * An administrator submitting an emailed sign-in code (IAM-001, ADR-0012).
 *
 * <p>Same shape as {@link VerifyOtpCommand} with an email address in place of a phone number — the
 * two identifier kinds are kept in separate commands so a caller cannot pass one where the other is
 * expected and have it silently match nothing.
 *
 * @param clientType decides the refresh lifetime, so it is required and never defaulted — the
 *     default would silently decide how long a stolen token stays usable
 * @param deviceIdentifier a human-readable label shown in the session list. Optional.
 */
public record VerifyEmailOtpCommand(
    String email, String otp, String clientType, String deviceIdentifier, String sourceIp) {}
