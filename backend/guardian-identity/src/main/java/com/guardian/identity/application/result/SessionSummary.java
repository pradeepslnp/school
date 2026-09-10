package com.guardian.identity.application.result;

import java.time.Instant;

/**
 * One of a user's sessions, as the "my sessions" screen shows it (feature IAM-004).
 *
 * <p>Carries no token material — not the refresh hash, not the family id. A person checking this
 * list wants to recognise their own devices and spot one they do not; the cryptographic plumbing is
 * not part of that and is never sent.
 *
 * @param current whether this is the session the request was made from — the one row the UI must
 *     not offer a "sign out" button that would end the call mid-action
 * @param status {@code ACTIVE}, {@code REVOKED}, or {@code EXPIRED} — a plain rollup of the
 *     domain's revoked flag and expiry, so the client does not re-derive lifecycle from timestamps
 */
public record SessionSummary(
    String id,
    String clientType,
    String deviceIdentifier,
    Instant issuedAt,
    Instant expiresAt,
    String status,
    boolean current) {}
