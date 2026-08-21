package com.guardian.identity.application.command;

/**
 * A member of staff submitting email and password.
 *
 * @param clientType decides the refresh lifetime, so it is required and never defaulted — the
 *     default would silently decide how long a stolen token stays usable. {@code ADMIN_WEB} carries
 *     the shortest lifetime of the three clients (SECURITY_ARCHITECTURE.md §Authentication): this
 *     is the highest-privilege human surface on the platform.
 */
public record StaffLoginCommand(
    String email, String password, String clientType, String sourceIp) {}
