package com.guardian.identity.application.command;

/**
 * A guardian asking for a code.
 *
 * @param phone as typed. Normalisation belongs to {@code PhoneNumber}, not to the caller, so every
 *     entry point normalises identically.
 * @param sourceIp the caller's address, recorded on the audit event. Rate limiting applies per
 *     number <em>and</em> per source: limiting only by number lets one host walk a list of numbers,
 *     and limiting only by source lets a botnet hammer one number.
 */
public record RequestOtpCommand(String phone, String sourceIp) {}
