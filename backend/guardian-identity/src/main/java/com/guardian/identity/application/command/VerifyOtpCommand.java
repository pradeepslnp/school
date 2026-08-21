package com.guardian.identity.application.command;

/**
 * A guardian submitting a code.
 *
 * @param clientType decides the refresh lifetime, so it is required and never defaulted — the
 *     default would silently decide how long a stolen token stays usable
 * @param deviceIdentifier a human-readable handset label shown in the session list, so a parent can
 *     recognise and revoke a device they no longer have. Optional.
 */
public record VerifyOtpCommand(
    String phone, String otp, String clientType, String deviceIdentifier, String sourceIp) {}
